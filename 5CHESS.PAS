program chess_5;
{$M 16384,0,655360}
uses crt,graph;
const steps=2;
      win=512;
      lose=-512;
      states=16;
      state1:array[1..states] of string[7]=
        ('11111','011110','011112','211110','11101','11011','10111',
         '2011102','01110','011010','010110','21110','01112',
         '01100','00110','01010');
      state2:array[1..states] of string[7]=
        ('22222','022220','022221','122220','22202','22022','20222',
         '1022201','02220','022020','020220','12220','02221',
         '02200','00220','02020');
      score:array[1..states] of integer=
        (   4096,     512,       8,       8,      8,      8,      8,
               2,       8,       6,       6,      2,      2,
               2,       2,       1);
var gd,gm:integer;
    p1,p2,p:(keyboard,computer);
    first:byte;
    minmax:array[1..steps] of integer;
    ToPut:array[1..361] of
            record
              x,y:byte;
            end;
    stored:integer;
    x1,x2,y1,y2:integer;
    screen:pointer;
    filename:string;
    mode:(Playing,ToSave,ToLoad);
    ch,ch1:char;
procedure cgadriver; external;
{$L cga.obj}
procedure hercdriver; external;
{$L herc.obj}
procedure readkbd(var ch,ch1:char);
  begin
    ch:=readkey;
    if ch=#0 then ch1:=readkey
             else ch1:=#0;
    if ch=^S
      then
        begin
          mode:=ToSave;
          ch:=#27;
        end
      else
        if ch=^L
          then
            begin
              mode:=ToLoad;
              ch:=#27;
            end;
  end;
procedure getch(var ch,ch1:char);
  begin
    ch:=readkey;
    if ch=#0 then ch1:=readkey
             else ch1:=#0;
  end;
procedure getstr(var s:string;len:integer);
  const y=0;
  var ch,ch1:char;
      i:integer;
  procedure clear(loc:byte);
    begin
      bar(8*loc,y+8,8*loc+7,y+15);
    end;
  begin
    getimage(0,y+0,319,y+20,screen^);
    bar(0,y+0,319,y+20); rectangle(0,y+4,319,y+20);
    bar(100,y+0,219,y+7);
    outtextxy(100,y+0,'Enter file name');
    s:='';
    outtextxy(8,y+8,'_');
    repeat
      ch:=readkey; if ch=#0 then ch1:=readkey;
      if (ch<>#13) and (ch<>#27) then
        begin
          if (ch=#0) and (ch1=#75) then ch:=#8;
          case ord(ch) of
           8: if s<>'' then
                begin
                  clear(succ(length(s))); clear(length(s));
                  delete(s,length(s),1);
                  outtextxy(8*length(s)+8,y+8,'_');
                end;
           32..255: if length(s)<len then
                      begin
                        s:=s+ch;
                        clear(length(s));
                        outtextxy(8*length(s),y+8,ch+'_');
                      end;
          end;
        end;
    until (ch=#13) or (ch=#27);
    clear(succ(length(s)));
    putimage(0,y+0,screen^,CopyPut);
    if ch=#27
      then s:=' '
      else
        begin
          for i:=1 to length(s) do
            s[i]:=upcase(s[i]);
          while copy(s,1,1)=' ' do
            delete(s,1,1);
          while (s<>'') and (copy(s,length(s),1)=' ') do
            delete(s,length(s),1);
          if pos(' ',s)<>0
            then s:='';
        end;
  end;
procedure play;
  type chessmode=array[0..18,0..18] of byte;
       chesstype=record
                   player:byte;
                   mode:chessmode;
                 end;
  var i,j,done:integer;
      xx,yy,color:integer;
      black,white,ThreeChar,ChessImage:pointer;
      chess:chessmode;
      buf:chesstype;
      f:file of chesstype;
      ch,ch1:char;
  procedure writemsg;
    begin
      moveto(0,90);
      outtext('1: ');
      if p1=keyboard then outtext('Keyboard')
                     else outtext('Computer');
      moveto(0,100);
      outtext('2: ');
      if p2=keyboard then outtext('Keyboard')
                     else outtext('Computer');
      moveto(0,110);
      if first=1 then outtext('1')
                 else outtext('2');
      outtext(' goes first');
    end;
  procedure start;
    const dx:array[1..8] of -1..1=(-1,1,-1, 1, 0,0,-1,1);
          dy:array[1..8] of -1..1=(-1,1, 1,-1,-1,1, 0,0);
    var i,j,k,m:integer;
        player,x,y,cx,cy:byte;
        s:string;
        quit:boolean;
    procedure drawchess(x,y:byte;player:byte);
      begin
        setcolor(0);
        line(x*10+100-3,y*10,x*10+100+3,y*10);
        line(x*10+100,y*10-3,x*10+100,y*10+3);
        setcolor(color);
        circle(x*10+100,y*10,4);
        if player=1 then
          begin
            setfillstyle(SolidFill,color);
            floodfill(x*10+100,y*10,color);
            setfillstyle(SolidFill,0);
          end;
      end;
    function scr(x,y:shortint):integer;
      type st9=string[9];
      var i,j:integer;
          k:integer;
          xx,yy:shortint;
          s:st9;
      function value(var s:st9):integer;
        var i,j:integer;
            k:integer;
            counter:byte;
        begin
          k:=0; counter:=0;
          for i:=1 to states do
            begin
              if pos(state1[i],s)<>0 then
                begin
                  inc(k,score[i]);
                  if i in [3..7,9..11] then
                    inc(counter);
                  i:=states;
                end;
              if pos(state2[i],s)<>0 then
                begin
                  dec(k,pred(score[i]));
                  if i in [3..7,9..11] then
                    inc(counter);
                  i:=states;
                end;
            end;
          if counter<2
            then value:=k
            else value:=256;
        end;
      begin
        k:=0;
        for i:=1 to 8 do
          if odd(i) then
            begin
              xx:=x; yy:=y; s:=chr(48+chess[xx,yy]);
              for j:=1 to 4 do
                begin
                  inc(xx,dx[i]); inc(yy,dy[i]);
                  if (xx<0) or (xx>18) or (yy<0) or (yy>18)
                    then s:='3'+s
                    else s:=chr(48+chess[xx,yy])+s;
                end;
              xx:=x; yy:=y;
              for j:=1 to 4 do
                begin
                  inc(xx,dx[succ(i)]); inc(yy,dy[succ(i)]);
                  if (xx<0) or (xx>18) or (yy<0) or (yy>18)
                    then s:=s+'3'
                    else s:=s+chr(48+chess[xx,yy]);
                end;
              k:=k+value(s);
            end;
        scr:=k;
      end;
    procedure FindBest(player:byte;var x,y:byte);
      var i,j,m,r:integer;
          ch,ch1:char;
      procedure search(s:integer);
        var i,j,k,oldm:integer;
            l,r,u,d:integer;
        function CanTry(i,j:integer):boolean;
          var k:integer;
          begin
            CanTry:=false;
            if chess[i,j]=0 then
              for k:=1 to 8 do
                if chess[i+dx[k],j+dy[k]]<>0 then
                  begin
                    CanTry:=true; k:=8;
                  end;
          end;
        procedure chk;
          var t:byte;
          begin
            if odd(s)
             then
              begin
               if k>minmax[s]
                 then
                   begin
                     minmax[s]:=k;
                     if s=1 then
                       begin
                         stored:=1;
                         with ToPut[1] do
                           begin
                             x:=i; y:=j;
                           end;
                       end;
                     for t:=1 to pred(s) do
                       if not odd(t) then
                         if minmax[t]<=k then
                           begin
                             i:=r; j:=d;
                           end;
                   end
                 else
                   if (s=1) and (k=minmax[s]) then
                     begin
                       inc(stored);
                       with ToPut[stored] do
                         begin
                           x:=i; y:=j;
                         end;
                     end;
              end
             else
              begin
               if k<minmax[s] then
                   begin
                     minmax[s]:=k;
                     for t:=1 to pred(s) do
                       if odd(s) then
                         if minmax[t]>=k then
                           begin
                             i:=r; j:=d;
                           end;
                   end;
              end;
          end;
        begin
          if not quit then
            if done+s>361
              then minmax[s]:=0
              else
                begin
                  for i:=0 to 18 do
                   for j:=0 to 18 do
                    if chess[i,j]<>0 then
                     begin
                      l:=pred(i); i:=18; j:=18;
                     end;
                  for j:=0 to 18 do
                   for i:=0 to 18 do
                    if chess[i,j]<>0 then
                     begin
                      u:=pred(j); i:=18; j:=18;
                     end;
                  for i:=18 downto 0 do
                   for j:=18 downto 0 do
                    if chess[i,j]<>0 then
                     begin
                      r:=succ(i); i:=0; j:=0;
                     end;
                  for j:=18 downto 0 do
                   for i:=18 downto 0 do
                    if chess[i,j]<>0 then
                     begin
                      d:=succ(j); i:=0; j:=0;
                     end;
                  if l<0 then l:=0;
                  if u<0 then u:=0;
                  if r>18 then r:=18;
                  if d>18 then d:=18;
                  if odd(s) then minmax[s]:=-maxint
                            else minmax[s]:=maxint;
                  oldm:=m;
                  for i:=l to r do
                   for j:=u to d do
                    if CanTry(i,j) then
                     begin
                      m:=oldm;
                      if odd(s) then chess[i,j]:=1
                                else chess[i,j]:=2;
                      if s=steps
                       then
                         begin
                           inc(m,scr(i,j));
                           k:=m;
                           chk;
                         end
                       else
                        begin
                         if not (((odd(s) and (minmax[s]>=win)) or
                                 ((not odd(s)) and (minmax[s]<=lose))))
                          then
                           begin
                            inc(m,scr(i,j));
                            if m<=2048
                              then
                                begin
                                  search(succ(s));
                                  k:=minmax[succ(s)];
                                end
                              else
                                k:=4096;
                            chk;
                           end;
                        end;
                      chess[i,j]:=0;
                     end;
                  if keypressed then
                    begin
                      readkbd(ch,ch1);
                      if ch=#27 then quit:=true;
                    end;
                end;
        end;
      begin
        if done=0
          then
            begin
              x:=9; y:=9;
            end
          else
            begin
              if player=2 then
                for i:=0 to 18 do
                  for j:=0 to 18 do
                    if chess[i,j]<>0 then
                      chess[i,j]:=3-chess[i,j];
              m:=0;
              stored:=0;
              search(1);
              repeat
                r:=succ(random(stored));
              until r<=stored;
              x:=ToPut[r].x; y:=ToPut[r].y;
              if player=2 then
                for i:=0 to 18 do
                  for j:=0 to 18 do
                    if chess[i,j]<>0 then
                      chess[i,j]:=3-chess[i,j];
            end;
      end;
    procedure getinput(player:byte;var x,y:byte);
      var ch,ch1:char;
          chosen:boolean;
      procedure cursor(x,y:byte);
        begin
          rectangle(x*10+100-5,y*10-5,x*10+100+5,y*10+5);
        end;
      begin
        setwritemode(XorPut);
        x:=cx; y:=cy;
        cursor(x,y);
        chosen:=false;
        repeat
          readkbd(ch,ch1);
          ch:=upcase(ch);
          cursor(x,y);
          if player=1
            then
              case ch of
               'I': if y>0 then dec(y);
               'J': if x>0 then dec(x);
               'K': if y<18 then inc(y);
               'L': if x<18 then inc(x);
               ' ': chosen:=true;
              end
            else
              begin
                if ch=#13
                  then chosen:=true
                  else
                    case ch1 of
                     #72: if y>0 then dec(y);
                     #75: if x>0 then dec(x);
                     #80: if y<18 then inc(y);
                     #77: if x<18 then inc(x);
                    end;
              end;
          cursor(x,y);
          if chosen then
            if chess[x,y]<>0 then
              begin
                sound(220); delay(200); nosound;
                chosen:=false;
              end;
        until (ch=#27) or chosen;
        cursor(x,y);
        if chosen
          then
            begin
              cx:=x; cy:=y;
            end
          else
            quit:=true;
        setwritemode(CopyPut);
      end;
    procedure go(player:byte;var x,y:byte);
      var ch,ch1:char;
      begin
        if player=1 then p:=p1
                    else p:=p2;
        if p=computer
          then FindBest(player,x,y)
          else getinput(player,x,y);
        if not quit then
          begin
            chess[x,y]:=player;
            cx:=x; cy:=y;
            drawchess(x,y,player);
            if keypressed then
              begin
                readkbd(ch,ch1);
                if ch=#27 then quit:=true;
              end;
          end;
      end;
    procedure err(s:string);
      const y=30;
      var i,j:integer;
          ch,ch1:char;
      begin
        s:='Error: '+s+' Press ESC.';
        i:=length(s)*8;
        getimage(3,y+3,13+i,y+21,screen^);
        bar(3,y+3,13+i,y+21);
        rectangle(3,y+3,13+i,y+21);
        rectangle(4,y+4,12+i,y+20);
        outtextxy(8,y+8,s);
        repeat
          getch(ch,ch1);
        until ch=#27;
        putimage(3,y+3,screen^,CopyPut);
      end;
    procedure load;
      var i,j,k,io,io1:integer;
          s:string;
      begin
        getstr(filename,37);
        if filename<>' ' then
          if (filename='') or (filename='CON')
            then err('Invalid filename.')
            else
              begin
                assign(f,filename);
                {$I-}
                reset(f); io:=IOResult;
                if io=0 then
                  begin
                    read(f,buf); io:=IOResult;
                  end;
                close(f); io1:=IOResult;
                {$I+}
                if (io<>0) or (io1<>0)
                  then err('File not found.')
                  else
                    begin
                      chess:=buf.mode;
                      if player<>buf.player then
                        begin
                          putimage(0,90,white^,XorPut);
                          putimage(0,100,white^,XorPut);
                        end;
                      player:=buf.player;
                      putimage(95,0,ChessImage^,CopyPut);
                      done:=0;
                      for j:=0 to 18 do
                        for k:=0 to 18 do
                          if chess[j,k]<>0 then
                            begin
                              inc(done);
                              drawchess(j,k,chess[j,k]);
                            end;
                      putimage(64,170,ThreeChar^,CopyPut);
                      str(done,s);
                      outtextxy(64,170,s);
                    end;
              end;
      end;
    procedure save;
      var i,io,io1:integer;
      begin
        getstr(filename,37);
        if filename<>' ' then
          if (filename='') or (filename='CON')
            then err('Invalid filename.')
            else
              begin
                buf.player:=player;
                buf.mode:=chess;
                assign(f,filename);
                {$I-}
                rewrite(f); io:=IOResult;
                if io=0 then
                  begin
                    write(f,buf); io:=IOResult;
                  end;
                close(f); io1:=IOResult;
                {$I+}
                if (io<>0) or (io1<>0) then
                  err('Unable to write.');
              end;
      end;
    begin
      done:=0; quit:=false;
      cx:=9; cy:=9;
      putimage(95,0,ChessImage^,CopyPut);
      putimage(0,130,black^,CopyPut);
      putimage(0,140,black^,CopyPut);
      putimage(0,160,black^,CopyPut);
      if first=1
        then putimage(0,90,white^,XorPut)
        else putimage(0,100,white^,XorPut);
      for i:=0 to 18 do
        for j:=0 to 18 do
          chess[i,j]:=0;
      player:=3-first;
      putimage(0,170,black^,CopyPut);
      outtextxy(8,170,'Steps: 0');
      repeat
        player:=3-player;
        repeat
          mode:=Playing;
          go(player,x,y);
          if mode<>Playing then
            begin
              quit:=false;
              if mode=ToLoad then load
                             else save;
            end;
        until mode=Playing;
        inc(done);
        putimage(0,90,white^,XorPut);
        putimage(0,100,white^,XorPut);
        if not quit then
          begin
            putimage(64,170,ThreeChar^,CopyPut);
            str(done,s);
            outtextxy(64,170,s);
          end;
      until quit or (done=361) or (abs(scr(x,y))>2048);
      if player=1
        then putimage(0,100,white^,XorPut)
        else putimage(0,90,white^,XorPut);
      if not quit then
        begin
          if done=361
            then outtextxy(0,160,'**  draw  **')
            else
              if player=1 then outtextxy(0,160,'* (1) wins *')
                          else outtextxy(0,160,'* (2) wins *');
        end;
    end;
  begin
    p1:=computer;
    p2:=keyboard;
    first:=2;
    mode:=Playing;
    getmem(black,imagesize(0,0,95,9));
    getimage(0,0,95,9,black^);
    getmem(ThreeChar,imagesize(64,170,87,177));
    getimage(64,170,87,177,ThreeChar^);
    getmem(screen,imagesize(0,0,319,20));
    xx:=getmaxx; yy:=getmaxy; color:=getcolor;
    setfillstyle(SolidFill,0);
    x1:=(xx+1-320) div 2; y1:=(yy+1-181) div 2;
    x2:=(xx+1+320) div 2-1; y2:=(yy+1+181) div 2-1;
    setviewport(x1,y1,x2,y2,ClipOn);
    outtextxy(0,0, '  5-Chess');
    outtextxy(0,10,' Copyright');
    outtextxy(0,20,'1991.5.13.');
    outtextxy(0,30,'    by    ');
    outtextxy(0,40,'Yang Cheng');
    for i:=0 to 18 do
      begin
        line(i*10+100,0,i*10+100,180);
        line(100,i*10,280,i*10);
      end;
    getmem(ChessImage,imagesize(95,0,285,180));
    getimage(95,0,285,180,ChessImage^);
    getmem(white,imagesize(0,90,87,97));
    setfillstyle(SolidFill,color);
    bar(0,90,87,97);
    getimage(0,90,87,97,white^);
    putimage(0,90,white^,XorPut);
    setfillstyle(SolidFill,0);
    writemsg;
    repeat
      outtextxy(16,130,'<RETURN>');
      outtextxy(16,140,'to begin');
      repeat
        getch(ch,ch1);
        case ch of
         '1': begin
                if p1=keyboard then p1:=computer
                               else p1:=keyboard;
                putimage(0,90,black^,CopyPut);
                writemsg;
              end;
         '2': begin
                if p2=keyboard then p2:=computer
                               else p2:=keyboard;
                putimage(0,100,black^,CopyPut);
                writemsg;
              end;
         ' ': begin
                first:=3-first;
                putimage(0,110,black^,CopyPut);
                writemsg;
              end;
        end;
      until ch in [#13,#27];
      if ch=#13 then start;
    until ch=#27;
  end;
begin
  CheckBreak:=false;
  if maxavail<18000 then
    begin
      writeln('Not enough memory.');
      halt(3);
    end;
  randomize;
  if registerbgidriver(@cgadriver)<0 then
    begin
      writeln('Graphics error.');
      halt(1);
    end;
  if registerbgidriver(@hercdriver)<0 then
    begin
      writeln('Graphics error.');
      halt(1);
    end;
  gd:=detect;
  detectgraph(gd,gm);
  if gd in [CGA,MCGA,EGA,EGA64,EGAMono,VGA]
    then
      begin
        gd:=cga; gm:=cgac2;
      end
    else
      if gd=HercMono
        then
          begin
            gd:=HercMono; gm:=HercMonoHi;
          end
        else
          begin
            writeln('CGA,EGA,VGA or Herc card required.');
            halt(2);
          end;
  clrscr;
  writeln('*** 5-chess V1.1 copyright 1991.5.13. by Yang Cheng ***');
  writeln;
  writeln('Keys to use:');
  writeln;
  writeln('1,2: Set player 1,2 (Keyboard or Computer)');
  writeln('<Space Bar>: Choose who goes first');
  writeln('<RETURN>: Start playing');
  writeln('<ESC>: exit');
  writeln;
  writeln('While playing:');
  write  ('  Player 1:  I, J, K, L to go up,left,down,right; ');
  writeln('<Space Bar> to put chess');
  write  ('  Player 2:  Arrow keys to go up,left,down,right; ');
  writeln('<RETURN> to put chess');
  writeln('  <Ctrl-S> to save game');
  writeln('  <Ctrl-L> to load game');
  writeln('  <ESC> to quit game');
  writeln;
  writeln;
  write('Press any key to start......');
  getch(ch,ch1);
  clrscr;
  initgraph(gd,gm,'');
  play;
  closegraph;
end.
