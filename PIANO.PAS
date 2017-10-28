program piano;  { ver 1.1 }
{$M 65520,0,0}
{$V-}
{$F+}
uses dos,crt;
const vec=$09;
      s:array[1..83] of integer=
        (495,520,585,660,700,780,880,990,1040,1170,1320,1400,1560,1760,
         467,552,622,0,740,830,935,0,1105,1245,0,1480,1660,1870,
         0,390,440,495,520,585,660,0,0,0,0,0,0,
         0,0,415,467,0,552,622,0,0,0,0,0,0,0,0,0,0,
         390,440,415,467,0,0,0,0,0,0,1980,2080,
         1870,0,0,0,0,0,0,0,0,0,0,0,0);
           { 520,585,660,700,780,880,990,1040
           {  1   2   3   4   5   6   7   1        }
           { 880,990,1040,1170,1320,1400,1560,1760 }
           {  6   7    1    2    3    4    5    6  }
      MaxSongs=25;
      MaxStore=600;
      TopMsg=11;
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
var key,j,k,p,pp,ii,jj,tail:integer;
    caps:boolean;
    old:pointer;
    pressed:array[0..127] of boolean;
    sn,quit,ok,empty:boolean;
    memo:memotype;
    ss:string[35];
    song:integer;
    rec:boolean;
    recptr,RecCounter:integer;
    oldtime,tm:longint;
    fo:file of onetype;
    fa:file of memotype;
procedure keyintr(Flags,CS,IP,AX,BX,CX,DX,SI,DI,DS,ES,BP:word);
  interrupt;
  begin
    key:=port[$60];
    port[$61]:=port[$61] or $80;
    port[$61]:=port[$61] and $7F;
    if key>=128
      then pressed[key and $7F]:=false
      else pressed[key]:=true;
    if key=58 then caps:=not caps;
    port[$20]:=$20;
  end;
function kbd:integer;
  begin
    inline($FA); kbd:=key; inline($FB);
  end;
function NowTime:longint;
  var h,m,s,f:word;
  begin
    gettime(h,m,s,f);
    NowTime:=h*360000+m*6000+s*100+f;
  end;
procedure WriteSongMsg;
  var s:string[35];
  begin
    window(1,1,80,25);
    gotoxy(45,17); write('Song Number: ',song:2,'   -- '); clreol;
    if memo[song].msg[1].h<>0
      then write('Recorded')
      else write('Not recorded');
    gotoxy(41,18); clreol;
    s:=memo[song].name;
    if s<>'' then
      begin
        gotoxy(58-length(s) div 2,18);
        write('<',s,'>');
      end;
    gotoxy(28,24);
  end;
procedure writemsg;
  begin
    window(1,TopMsg,40,25); clrscr;
    window(1,1,80,25);
    gotoxy(1,TopMsg);
    writeln('<Shift> -------- Higher');
    writeln('<Space Bar> ---- Lower');
    writeln('<Alt-R> -------- Record');
    writeln('<Alt-L> -------- Listen');
    writeln('<Alt-A> -------- Append');
    writeln('<Alt-'#27'> -------- Previous song');
    writeln('<Alt-'#26'> -------- Next song');
    writeln('<Alt-N> -------- Rename this song');
    writeln('<Alt-C> -------- Clear this song');
    writeln('<Alt-S> -------- Save');
    writeln('<Alt-D> -------- Load');
    writeln('<Ctrl-Alt-Del> - Clear all');
    writeln('---------------------------------');
    write  ('Press <Alt-Q> to quit......');
    WriteSongMsg;
  end;
procedure clrkey;
  begin
    inline($FA); key:=0; inline($FB);
  end;
procedure play;
  var ii,j,k,m:integer;
      n:longint;
      quit,pause,trc:boolean;
  begin
    window(1,TopMsg,40,25); clrscr; window(1,1,80,25);
    gotoxy(1,15); writeln('Playing......');
    writeln;
    writeln('<'#27'><'#26'>:      Slower/Faster');
    writeln('<'#26'>+<PgDn>:  Fastest');
    writeln('<Shift>:     Higher');
    writeln('<Space bar>: Lower');
    writeln('<Alt-S>:     Pause');
    writeln('<Alt-T>:     Truncate');
    writeln('------------------------------');
    write('Press <Alt-End> to quit......');
    quit:=false; pause:=false; trc:=false;
    ii:=0;
    repeat
      if pressed[56] and pressed[79]
        then quit:=true
        else
          begin
            inc(ii);
            if ii>MaxStore
              then quit:=true
              else
                begin
                  j:=memo[song].msg[ii].h;
                  if j=0
                    then quit:=true
                    else
                      begin
                        if j=rest
                          then nosound
                          else
                            begin
                              k:=j;
                              if pressed[42] or pressed[54]
                                then k:=k*2;
                              if pressed[57] and (k>=390)
                                then k:=k div 2;
                              sound(k);
                            end;
                        n:=memo[song].msg[ii].l;
                        if pressed[75] then n:=n*2;
                        if pressed[77] then n:=n div 2;
                        if pressed[77] and pressed[81]
                          then n:=n div 2;
                        for m:=1 to n do
                          begin
                            oldtime:=NowTime;
                            if pressed[56] then
                              if pressed[79]
                                then
                                  begin
                                    quit:=true;
                                    m:=n;
                                  end
                                else
                                  if pressed[31]
                                    then pause:=true
                                    else
                                      if pressed[20]
                                        then trc:=true;
                            repeat
                            until oldtime<>NowTime;
                          end;
                      end;
                end;
          end;
      if not quit then
        begin
          if pause then
            begin
              nosound;
              gotoxy(1,24); clreol;
              write('Paused. Press <RETURN> to continue......');
              repeat
              until pressed[28];
              clrkey;
              gotoxy(1,24); clreol;
              write('Press <Alt-End> to quit......');
              clrkey;
              pause:=false;
            end;
          if trc then
            begin
              nosound;
              gotoxy(1,24); clreol;
              write('Truncate here (Y/N)?');
              repeat
              until pressed[21] or pressed[49] or pressed[1];
              if pressed[21]
                then
                  begin
                    gotoxy(1,24); clreol;
                    quit:=true;
                    if ii<MaxStore then
                      memo[song].msg[succ(ii)].h:=0;
                  end
                else
                  begin
                    gotoxy(1,24); clreol;
                    write('Press <Alt-End> to quit......');
                  end;
              clrkey;
              trc:=false;
            end;
        end;
    until quit;
    nosound;
    clrkey;
    writemsg;
  end;
procedure getstr(var s:string;len:integer);
  const st:string=
           ' 1234567890-=  qwertyuiop[]  asdfghjkl;''` \zxcvbnm,./ *   '+
           '            789- 56+1230.';
        sf:string=
           ' !@#$%^&*()_+  QWERTYUIOP{}  ASDFGHJKL:"~ |ZXCVBNM<>?     '+
           '            789- 56+1230.';
  var j:integer;
      ch:char;
  begin
    s:='';
    repeat
      clrkey;
      repeat
        j:=kbd;
      until j in [1..127];
      if pressed[42] or pressed[54]
        then ch:=sf[j]
        else ch:=st[j];
      if caps then
        if (ch in ['A'..'Z'])
          then ch:=chr(ord(ch)+32)
          else
            if (ch in ['a'..'z'])
              then ch:=chr(ord(ch)-32);
      if (ch=' ') and not (j in [57,14,75,28,1]) then ch:=#0;
      if ch<>#0 then
        begin
          if not (j in [28,1]) then
            if j in [14,75]
              then
                begin
                  if length(s)>0 then
                    begin
                      write(^H' '^H);
                      delete(s,length(s),1);
                    end;
                end
              else
                if length(s)<len then
                  begin
                    s:=s+ch;
                    write(ch);
                  end;
        end;
    until j in [28,1];
    if j=1 then s:=#0;
    writeln;
    clrkey;
  end;
procedure ReportErr(s:string);
  begin
    gotoxy(1,24); write('Error: ',s,' Press ESC.');
    repeat
    until pressed[1];
  end;
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
procedure save;
  var all,ok,empty:boolean;
      s:string;
      io,ii:integer;
  begin
    window(1,TopMsg,40,25); clrscr;
    window(1,1,80,25);
    gotoxy(1,19); writeln('*** Save Song ***');
    writeln; write('Save this song (T) or all the songs (A)?');
    repeat
    until pressed[20] or pressed[30] or pressed[1];
    if pressed[30] then all:=true
                   else all:=false;
    if kbd=1 then
      begin
        writemsg;
        clrkey;
        exit;
      end;
    if all then writeln('A')
           else writeln('T');
    if (not all) and (memo[song].msg[1].h=0) and (memo[song].name='')
      then
        begin
          ReportErr('Nothing to save.');
          gotoxy(1,21); clreol;
          writemsg;
          clrkey;
          exit;
        end;
    if all then
      begin
        empty:=true;
        for ii:=1 to MaxSongs do
          if (memo[ii].msg[1].h<>0) or (memo[ii].name<>'') then
            begin
              empty:=false; ii:=MaxSongs;
            end;
        if empty then
          begin
            ReportErr('Nothing to save.');
            gotoxy(1,21); clreol;
            writemsg;
            clrkey;
          end;
      end;
    if all and empty then exit;
    repeat
      gotoxy(1,22); write('Filename:'); clreol;
      getstr(s,70);
      DelSp(s);
    until (s<>'') and (s<>'CON');
    if s<>#0 then
      begin
        {$I-}
        io:=0; ok:=true;
        if all
          then
            begin
              assign(fa,s);
              reset(fa);
              if IOResult=0 then
                begin
                  gotoxy(1,23);
                  write('File already exists. Overwrite (Y/N)?');
                  repeat
                  until pressed[21] or pressed[49] or pressed[1];
                  if not pressed[21] then ok:=false;
                  gotoxy(1,23); clreol;
                end;
              close(fa); io:=IOResult; io:=0;
              if ok then
                begin
                  rewrite(fa);
                  if IOResult<>0 then io:=1;
                  if io=0 then
                    write(fa,memo);
                  if IOResult<>0 then io:=1;
                  close(fa);
                  if IOResult<>0 then io:=1;
                end;
            end
          else
            begin
              assign(fo,s);
              reset(fo);
              if IOResult=0 then
                begin
                  gotoxy(1,23);
                  write('File already exists. Overwrite (Y/N)?');
                  repeat
                  until pressed[21] or pressed[49] or pressed[1];
                  if not pressed[21] then ok:=false;
                  gotoxy(1,23); clreol;
                end;
              close(fo); io:=IOResult; io:=0;
              if ok then
                begin
                  rewrite(fo);
                  if IOResult<>0 then io:=1;
                  if io=0 then
                    write(fo,memo[song]);
                  if IOResult<>0 then io:=1;
                  close(fo);
                  if IOResult<>0 then io:=1;
                end;
            end;
        {$I+}
        if io<>0 then ReportErr('Invalid file name.');
      end;
    gotoxy(1,21); clreol;
    gotoxy(1,22); clreol;
    writemsg;
    clrkey;
  end;
procedure load;
  var all,ok:boolean;
      s:string;
      io,ii:integer;
  begin
    window(1,TopMsg,40,25); clrscr;
    window(1,1,80,25);
    gotoxy(1,19); writeln('*** Load Song ***');
    writeln; write('Load one song (O) or a set of songs (A)?');
    repeat
    until pressed[24] or pressed[30] or pressed[1];
    if pressed[30] then all:=true
                   else all:=false;
    if kbd=1 then
      begin
        writemsg;
        clrkey;
        exit;
      end;
    if all then writeln('A')
           else writeln('O');
    repeat
      gotoxy(1,22); write('Filename:'); clreol;
      getstr(s,70);
      DelSp(s);
    until (s<>'') and (s<>'CON');
    if s<>#0 then
      begin
        {$I-}
        io:=0;
        if all
          then
            begin
              ok:=true;
              for ii:=1 to MaxSongs do
                if (memo[ii].msg[1].h<>0) or (memo[ii].name<>'')
                  then
                    begin
                      ok:=false; ii:=MaxSongs;
                    end;
              if not ok then
                begin
                  gotoxy(40,23);
                  write('Overwrite all the songs (Y/N)?');
                  repeat
                  until pressed[21] or pressed[49] or pressed[1];
                  if pressed[21] then ok:=true;
                  clrkey;
                  gotoxy(40,23); clreol;
                end;
              if ok then
                begin
                  assign(fa,s);
                  reset(fa);
                  if IOResult<>0 then io:=1;
                  if io=0 then
                    read(fa,memo);
                  if IOResult<>0 then io:=1;
                  close(fa);
                  if IOResult<>0 then io:=1;
                end;
            end
          else
            begin
              ok:=true;
              if memo[song].msg[1].h<>0 then
                begin
                  gotoxy(40,23);
                  write('Overwrite this song (Y/N)?');
                  repeat
                  until pressed[21] or pressed[49] or pressed[1];
                  if not pressed[21] then ok:=false;
                  clrkey;
                  gotoxy(40,23); clreol;
                end;
              if ok then
                begin
                  assign(fo,s);
                  reset(fo);
                  if IOResult<>0 then io:=1;
                  if io=0 then
                    read(fo,memo[song]);
                  if IOResult<>0 then io:=1;
                  close(fo);
                  if IOResult<>0 then io:=1;
                end;
            end;
        {$I+}
        if io<>0 then ReportErr('File not found.');
      end;
    gotoxy(1,21); clreol;
    gotoxy(1,22); clreol;
    writemsg;
    clrkey;
  end;
procedure rename;
  var s:string[35];
  begin
    window(1,TopMsg,40,25); clrscr; window(1,1,80,25);
    gotoxy(1,17); writeln('*** Rename ***');
    writeln; writeln('Old name: ',memo[song].name);
    write('New name: ');
    getstr(s,35);
    if s<>#0 then memo[song].name:=s;
    gotoxy(1,19); clreol;
    gotoxy(1,20); clreol;
    writemsg;
  end;
procedure clear;
  begin
    if (memo[song].msg[1].h<>0) or (memo[song].name<>'') then
      begin
        window(1,1,80,25); gotoxy(40,23);
        write('Are you sure to clear it (Y/N)?');
        repeat
        until pressed[21] or pressed[49] or pressed[1];
        if pressed[21] then
          begin
            memo[song].msg[1].h:=0; memo[song].name:='';
          end;
        gotoxy(40,23); clreol;
        clrkey;
      end;
    writemsg;
  end;
procedure writefull;
  begin
    rec:=false; nosound;
    window(1,TopMsg,40,25); clrscr; window(1,1,80,25);
    gotoxy(1,20); write('Memory full. Press ESC.');
    clrkey;
    repeat
    until kbd=1;
    clrkey;
    gotoxy(1,23); write('Name: ');
    getstr(ss,35);
    if ss<>#0 then memo[song].name:=ss;
    writemsg;
  end;
begin
  caps:=false;
  getintvec(vec,old);
  setintvec(vec,@keyintr);
  for ii:=0 to 83 do
    pressed[ii]:=false;
  for ii:=1 to MaxSongs do
    with memo[ii] do
      begin
        msg[1].h:=0; name:='';
      end;
  quit:=false;
  sn:=false;
  rec:=false;
  inline($FA); key:=128; inline($FB);
  p:=0;
  song:=1;
  textmode(BW80);
  clrscr;
  writeln('*******************************');
  writeln('*                             *');
  writeln('*            PIANO            *');
  writeln('*        ( VER.  1.1 )        *');
  writeln('* --------------------------- *');
  writeln('*     Copyright 1991.5.11     *');
  writeln('*        by Yang Cheng        *');
  writeln('*                             *');
  writeln('*******************************');
  writemsg;
  WriteSongMsg;
  repeat
    if pressed[56] and pressed[19] and not rec then
      begin
        ok:=true;
        if memo[song].msg[1].h<>0 then
          begin
            gotoxy(40,22); write('Overwrite this song (Y/N)?');
            repeat
            until pressed[21] or pressed[49] or pressed[1];
            if not pressed[21] then ok:=false;
            gotoxy(40,22); clreol;
            writemsg;
            clrkey;
          end;
        if ok then
          begin
            rec:=true; recptr:=1;
            with memo[song].msg[recptr] do
              begin
                h:=rest; l:=0;
              end;
            window(1,TopMsg,40,25); clrscr; window(1,1,80,25);
            gotoxy(1,17); writeln('Recording......');
            writeln; write('Press <Alt-End> to quit......');
            repeat
            until not pressed[19];
            oldtime:=NowTime;
          end;
      end;
    if pressed[56] and pressed[30] and not rec then
      begin
        window(1,TopMsg,40,25); clrscr; window(1,1,80,25);
        tail:=0;
        for ii:=1 to MaxStore do
          if memo[song].msg[ii].h=0 then
            begin
              tail:=ii; ii:=MaxStore;
            end;
        if tail=1
          then
            begin
              gotoxy(1,23);
              write('Nothing in this song. ');
              write('Please use <Alt-R> to record.   Press ESC.');
              clrkey;
              repeat until kbd=1;
              clrkey;
              gotoxy(1,23); clreol;
              writemsg;
            end
          else
            if tail=0
              then
                begin
                  ReportErr('No memory.');
                  clrkey;
                  writemsg;
                end
              else
                begin
                  gotoxy(1,20); write('Now please start......');
                  clrkey;
                  repeat until kbd in [1..127];
                  gotoxy(1,20); clreol;
                  rec:=true; recptr:=pred(tail);
                  gotoxy(1,17); writeln('Recording......');
                  writeln; write('Press <Alt-End> to quit......');
                  oldtime:=NowTime;
                end;
      end;
    if rec and pressed[56] and pressed[79] then
      begin
        inc(recptr);
        if recptr<=MaxStore then memo[song].msg[recptr].h:=0;
        rec:=false;
        gotoxy(1,23); write('Name: ');
        getstr(ss,35);
        if ss<>#0 then memo[song].name:=ss;
        gotoxy(1,23); clreol;
        writemsg;
      end;
    if (not rec) and pressed[56] then
      begin
        if pressed[56] and pressed[29] and pressed[83] then
          begin
            empty:=true;
            for jj:=1 to MaxSongs do
              if (memo[jj].msg[1].h<>0) or (memo[jj].name<>'') then
                begin
                  empty:=false; jj:=MaxSongs;
                end;
            if not empty then
              begin
                gotoxy(37,23);
                write('Are you sure to clear all the songs (Y/N)?');
                repeat
                until pressed[21] or pressed[49] or pressed[1];
                if pressed[21] then
                  for jj:=1 to MaxSongs do
                    begin
                      memo[jj].msg[1].h:=0;
                      memo[jj].name:='';
                    end;
                gotoxy(37,23); clreol;
              end;
            clrkey;
            writemsg;
          end;
        if pressed[56] and pressed[38] then play;
        if pressed[56] and pressed[31] then save;
        if pressed[56] and pressed[32] then load;
        if pressed[56] and pressed[46] then clear;
        if pressed[56] and pressed[49] then rename;
        if pressed[56] and (kbd=75) then
          begin
            dec(song); if song<1 then song:=MaxSongs;
            WriteSongMsg;
            clrkey;
          end;
        if pressed[56] and (kbd=77) then
          begin
            inc(song); if song>MaxSongs then song:=1;
            WriteSongMsg;
            clrkey;
          end;
      end;
    if not pressed[56] then
      begin
        pp:=kbd;
        if pp in [1..127] then
          begin
            p:=pp;
            if s[p]>0
              then
                begin
                  k:=s[p];
                  if pressed[42] or pressed[54] then k:=k*2;
                  if pressed[57] then k:=k div 2;
                  sound(k);
                  sn:=true;
                  if rec then
                    if k<>memo[song].msg[recptr].h then
                      begin
                        inc(recptr);
                        if recptr<=MaxStore
                          then
                            with memo[song].msg[recptr] do
                              begin
                                h:=k; l:=0;
                              end
                          else
                            writefull;
                      end;
                end
              else
                begin
                  nosound; sn:=false;
                  if rec and (memo[song].msg[recptr].h<>rest) then
                    begin
                      inc(recptr);
                      if recptr<=MaxStore
                        then
                          with memo[song].msg[recptr] do
                            begin
                              h:=rest; l:=0;
                            end
                        else
                          writefull;
                    end;
                end;
          end;
      end;
    if sn and not pressed[p] then
      begin
        nosound; sn:=false;
        if rec and (memo[song].msg[recptr].h<>rest) then
          begin
            inc(recptr);
            if recptr<=MaxStore
              then
                with memo[song].msg[recptr] do
                  begin
                    h:=rest; l:=0;
                  end
              else
                writefull;
          end;
      end;
    if rec then
      begin
        tm:=NowTime;
        if tm<>oldtime then
          begin
            oldtime:=tm;
            inc(memo[song].msg[recptr].l);
            if memo[song].msg[recptr].l=65535 then
              begin
                inc(recptr);
                if recptr<=MaxStore
                  then
                    with memo[song].msg[recptr] do
                      begin
                        h:=memo[song].msg[pred(recptr)].h; l:=0;
                      end
                  else
                    writefull;
              end;
          end;
      end;
    if not rec then
      if pressed[56] and pressed[16] then
        begin
          nosound;
          gotoxy(1,25);
          write('Are you sure you want to quit PIANO 1.1 (Y/N)?');
          repeat
          until pressed[21] or pressed[49] or pressed[1];
          if pressed[21]
            then
              begin
                quit:=true;
                gotoxy(1,25); clreol;
              end
            else
              begin
                gotoxy(1,25); clreol;
                writemsg;
              end;
          clrkey;
        end;
  until quit;
  nosound;
  window(1,1,80,25); gotoxy(26,24);
  writeln;
  setintvec(vec,old);
end.
