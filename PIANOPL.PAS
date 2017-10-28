program Piano_Player;   { ver 1.1 }
{$M 4096,0,0}
{$F+,S-}
uses dos,crt;
{ Vectors used:
  $D0: Installation flag;
  $D1: Old key-interrupt vector;
  $D2: Old clock-interrupt;
  $D3: Address of "memo";
  $D4: Address of "sn";
  $D5: Address of "song";
  $D6: Address of "time";
  $D7: Address of "songptr";
}
const code:record
             jmp:byte;
             addr:pointer;
           end=
             (jmp:$EA;
              addr:nil);
      MaxSongs=25;
      MaxStore=600;
      rest=65535;
type onetype=
       record
         msg:array[1..MaxStore] of
               record
                 h:word; l:byte;
               end;
         name:string[35];
       end;
     memotype=array[1..MaxSongs] of onetype;
var i,j,key:integer;
    pressed:array[0..127] of boolean;
    exist:boolean;
    fa:file of memotype;
    memo:memotype;
    sn:boolean;
    song,time:byte;
    songptr:integer;
    hh:word;
    old:pointer;
    old1C,new1C:pointer;
    r1,r2:registers;
    vecs:array[0..1023] of byte absolute $0000:$0000;
{
procedure getintvec(IntNo:byte;var p:pointer);
  var i:word;
  begin
    inline($FA);
    i:=IntNo*4;
    p:=ptr(vecs[i+3]*256+vecs[i+2],vecs[succ(i)]*256+vecs[i]);
    inline($FB);
  end;
procedure setintvec(IntNo:byte;p:pointer);
  var i,p1,p2:word;
  begin
    inline($FA);
    i:=IntNo*4;
    p1:=seg(p^); p2:=ofs(p^);
    vecs[i+3]:=Hi(p1);     vecs[i+2]:=Lo(p1);
    vecs[succ(i)]:=Hi(p2); vecs[i]:=Lo(p2);
    inline($FB);
  end;
}
procedure music(Flags,CS,IP,AX,BX,CX,DX,SI,DI,DS,ES,BP:word);
  interrupt;
  begin
    inline($FA);
    if sn then
      begin
        if time=0
          then
            begin
              inc(songptr);
              if (songptr>MaxStore) or (memo[song].msg[songptr].h=0)
                then
                  begin
                    inc(song); if song>MaxSongs then song:=1;
                    songptr:=0; time:=0;
                  end
                else
                  begin
                    time:=memo[song].msg[songptr].l;
                    if time>0 then dec(time);
                    hh:=memo[song].msg[songptr].h;
                    if hh=rest then nosound
                               else sound(hh);
                  end;
            end
          else
            dec(time);
      end;
    inline($FB);
    r2.ax:=ax; r2.bx:=bx; r2.cx:=cx; r2.dx:=dx;
    r2.bp:=bp; r2.si:=si; r2.di:=di;
    r2.ds:=ds; r2.es:=es; r2.flags:=flags;
    intr($D2,r2);
  end;
procedure keyintr(Flags,CS,IP,AX,BX,CX,DX,SI,DI,DS,ES,BP:word);
  interrupt;
  begin
    key:=port[$60];
    if key>=128
      then pressed[key and $7F]:=false
      else pressed[key]:=true;
    if pressed[56] and (key=38)
      then
        begin
          sn:=not sn;
          if sn=false then nosound;
          inline($FA);
          if sn=true then code.addr:=new1C
                     else code.addr:=old1C;
          inline($FB);
        end;
    if pressed[56] and (pressed[42] or pressed[54])
       and (key in [75,77,31,32])
      then
        begin
          port[$61]:=port[$61] or $80;
          port[$61]:=port[$61] and $7F;
          inline($FA);
          nosound;
          if key in [77,32] then inc(song);
          if key in [75,31] then dec(song);
          if song<1 then song:=MaxSongs;
          if song>MaxSongs then song:=1;
          songptr:=0; time:=0;
          inline($FB);
          port[$20]:=$20;
        end
      else
        begin
          r1.ax:=ax; r1.bx:=bx; r1.cx:=cx; r1.dx:=dx;
          r1.bp:=bp; r1.si:=si; r1.di:=di;
          r1.ds:=ds; r1.es:=es; r1.flags:=flags;
          port[$20]:=$20;
          intr($D1,r1);
        end;
  end;
procedure ChkKeep;
  begin
    if    (mem[$0000:$0340]<>$19) or (mem[$0000:$0341]<>$74)
       or (mem[$0000:$0342]<>$02) or (mem[$0000:$0343]<>$12)
      then
        begin
          exist:=false;
          mem[$0000:$0340]:=$19;
          mem[$0000:$0341]:=$74;
          mem[$0000:$0342]:=$02;
          mem[$0000:$0343]:=$12;
        end
      else
        begin
          writeln('Piano Player already installed.');
          exist:=true;
        end;
  end;
procedure load;
  var all,ok:boolean;
      s:string;
      io,ii:integer;
  procedure DelSp(var s:string);
    var j:integer;
    begin
      j:=1;
      while j<=length(s) do
        if s[j]=' ' then delete(s,j,1)
                    else inc(j);
      for j:=1 to length(s) do
        s[j]:=upcase(s[j]);
    end;
  procedure ReportErr(s:string);
    begin
      writeln(s);
      halt(2);
    end;
  begin
    if paramcount=0
      then s:=''
      else
        begin
          s:=paramstr(1);
          DelSp(s);
        end;
    if s='' then
      ReportErr('Filename must be given in the command line.');
    if s='CON' then ReportErr('Invalid filename.');
    {$I-}
    io:=0;
    assign(fa,s);
    reset(fa);
    if IOResult<>0 then io:=1;
    if io=0 then
      read(fa,memo);
    if IOResult<>0 then io:=1;
    close(fa);
    if IOResult<>0 then io:=1;
    {$I+}
    if io<>0 then ReportErr('File not found.');
  end;
procedure getvalue(vec:byte;var dest;size:word);
  var vec1:pointer;
      i:word;
  begin
    i:=vec*4;
    vec1:=ptr(vecs[i+3]*256+vecs[i+2],vecs[succ(i)]*256+vecs[i]);
    move(vec1^,dest,size);
  end;
procedure setvalue(var src;vec:byte;size:word);
  var vec1:pointer;
      i:word;
  begin
    i:=vec*4;
    vec1:=ptr(vecs[i+3]*256+vecs[i+2],vecs[succ(i)]*256+vecs[i]);
    move(src,vec1^,size);
  end;
begin
  load;
  ChkKeep;
  if not exist
    then
      begin
        for i:=0 to 127 do
          pressed[i]:=false;
        sn:=false;
        song:=1; songptr:=0; time:=0;
        writeln
          ('Piano Player V1.1 copyright 1991.5.11 by Yang Cheng.');
        writeln('Alt-L:  Music ON/OFF');
        writeln('Alt-Shift-'#27#26' (or Alt-Shift-S/D):  '+
                'Previous/Next song');
        setintvec($D3,@memo);
        setintvec($D4,@sn);
        setintvec($D5,@song);
        setintvec($D6,@time);
        setintvec($D7,@songptr);
        getintvec($09,old);
        setintvec($D1,old);
        getintvec($1C,old);
        setintvec($D2,old);
        old1C:=old; new1C:=@music;
        code.addr:=old;
        setintvec($1C,@code);
        setintvec($09,@keyintr);
        keep(1);
      end
    else
      begin
        inline($FA);
        getvalue($D4,sn,sizeof(boolean));
        if sn then
          begin
            sn:=false;
            nosound;
          end;
        setvalue(memo,$D3,sizeof(memotype));
        song:=1; songptr:=0; time:=0;
        setvalue(sn,$D4,sizeof(boolean));
        setvalue(song,$D5,sizeof(byte));
        setvalue(time,$D6,sizeof(byte));
        setvalue(songptr,$D7,sizeof(integer));
        inline($FB);
        writeln('New data transferred.');
      end;
end.
