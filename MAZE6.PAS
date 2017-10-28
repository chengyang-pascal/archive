program maze6 (input,output);  {ver 6.21}
{$M 65520,0,0}
{$V-}
uses crt,graph3,graph,dos,MazeUnit;
const maxx=99;
      maxy=34;
      step=6;
      c=1; {color}
      places=3400;  {places=maxx*maxy}
      dx:array[1..5] of -1..1 =(0 ,0,-1,1, 0);
      dy:array[1..5] of -1..1 =(-1,1, 0,0,-1);
      maxprt=10;
      maxtrea=9;
      maxmons=5;
      scrcode=80;
      scrfile='maze6.scr';
      cfgfile='maze6.cfg';
type modetype=(high,middle);
     hmktype=array[0..10] of record
                               name :string[6];
                               score:integer;
                             end;
var x,y :integer;
    c1,s,drv:string[128];
    i,j,pass,t,rx,ry :integer;
    ch  :char;
    retcode:integer;
    soun,visible,monster :boolean;
    maze,walls,wallh :array[0..maxx,0..maxy] of boolean;
    mazemt:array[1..maxx,1..maxy] of (normal,ATreasure,Apbox);
    drawn:array[1..maxx,1..maxy] of boolean;
    key :array[1..4] of record
                           first,next:char;
                         end;
    way :array[1..places] of record
                               x,y:integer;
                             end;
    steps :integer;
    blb,showed,fill,norec :boolean;
    WithFootPrint :boolean;
    buffer :array[0..16006] of byte;
    diffi,mspeed,ispeed :integer;
    mode   :modetype;
    nmx,nmy:integer;
    protect,treasures:integer;
    NumOfMons,mos:integer;
    mox,moy,monsd:array[1..maxmons] of integer;
    goright:array[1..maxmons] of boolean;
    add    :integer;
    hmk    :array[1..2] of hmktype;
    hmkptr :byte;
    hmkfile:file of hmktype;
    cfg    :file of integer;
    usefile:boolean;
    drive:char;
    beep:boolean;
    oldtime,newtime,oldtime1,newtime1:longint;
{----------------------------------------------------------}
procedure drawmazebox(x,y:integer);
  var i,c:integer;
  begin
    if fill and not drawn[x,y]
      then if mode=high then c:=1
                        else c:=2
      else c:=0;
    for i:=1 to pred(step) do
      draw((x-1)*step+1,(y-1)*step+i,x*step-1,(y-1)*step+i,c);
    if not fill or drawn[x,y] then
      begin
        if wallh[x,y-1] then
          draw((x-1)*step+1,(y-1)*step,x*step-1,(y-1)*step,0);
        if wallh[x,y] then
          draw((x-1)*step+1,y*step,x*step-1,y*step,0);
        if walls[x-1,y] then
          draw((x-1)*step,(y-1)*step+1,(x-1)*step,y*step-1,0);
        if walls[x,y] then
          draw(x*step,(y-1)*step+1,x*step,y*step-1,0);
      end;
    if mazemt[x,y]=Apbox then
      begin
        draw(x*step-1,y*step-1,x*step-5,y*step-5,1);
        draw(x*step-5,y*step-1,x*step-1,y*step-5,1);
      end;
    if mazemt[x,y]=ATreasure then
      begin
        draw(x*step-4,y*step-4,x*step-1,y*step-4,1);
        draw(x*step-1,y*step-4,x*step-1,y*step-2,1);
        draw(x*step-3,y*step-4,x*step-3,y*step-2,1);
      end;
    if (not fill) and (not norec) then drawn[x,y]:=true;
  end;
procedure drawmonster(x,y:integer);
  var c:integer;
  begin
    if (mode=high) and (not visible) and not drawn[x,y]
      then c:=0
      else c:=1;
    draw(x*step-5,y*step-1,x*step-1,y*step-1,c);
    draw(x*step-1,y*step-1,x*step-4,y*step-5,c);
    draw(x*step-4,y*step-5,x*step-5,y*step-1,c);
  end;
procedure ReportErr(st:st255);
  var ch,ch1:char;
  begin
    tc(14,15); bg(4,0);
    border(3,10,36,13,1,'Error');
    tc(15,7);
    gotoxy (2,1);  write (st);
    gotoxy (11,2); write ('Press ');
    tc(14,15); write ('ESC');
    tc(15,7); write ('.');
    tc(4,0); write (' ',^H);
    repeat
      ReadAKey(ch,ch1);
    until ch=#27;
  end;
{-----------------------------------------------------------}
procedure walk (x,y,dir:integer);
  var tx,ty,k :integer;
      fail  :boolean;
 procedure erase;
  begin
    maze[tx,ty]:=true;
    pass:=succ(pass);
    case dir of
     1: wallh[x,y-1]:=true;
     2: wallh[x,y]:=true;
     3: walls[x-1,y]:=true;
     4: walls[x,y]:=true;
    end;
   end;
  begin
    if pass<t then
      begin
        fail:=false;
        tx:=x+dx[dir]; ty:=y+dy[dir];
        if maze[tx,ty]
          then begin
                 fail:=true;
                 k:=0;
                 repeat
                   k:=succ(k);
                   tx:=x+dx[k]; ty:=y+dy[k];
                   if not maze[tx,ty] then fail:=false;
                 until (k=4) or not fail;
                 if not fail then
                   repeat
                     dir:=random(4)+1;
                     tx:=x+dx[dir]; ty:=y+dy[dir];
                   until not maze[tx,ty];
               end;
        if not fail then
          begin
            erase;
            walk (tx,ty,random(4)+1);
            for dir:=1 to 4 do
              begin
                tx:=x+dx[dir]; ty:=y+dy[dir];
                if not maze[tx,ty] then walk(x,y,dir);
              end;
          end;
      end;
  end;
procedure mouse (fromx,fromy,stack :integer);
  var successful:boolean;
      came :array[1..maxx,1..maxy] of boolean;
  procedure mousesub(fromx,fromy,stack:integer);
    var d:integer;
        tx,ty:integer;
        b:boolean;
    begin
      if not successful then
        begin
          with way[stack] do
            begin
              x:=fromx; y:=fromy
            end;
          if (fromx=x) and (fromy=1)
            then begin
                   steps:=stack;
                   successful:=true;
                 end
            else begin
                   for d:=1 to 4 do
                     begin
                       tx:=fromx+dx[d]; ty:=fromy+dy[d];
                       if not came[tx,ty] then
                         begin
                           b:=false;
                           case d of
                            1: b:=wallh[fromx  ,fromy-1];
                            2: b:=wallh[fromx  ,fromy  ];
                            3: b:=walls[fromx-1,fromy  ];
                            4: b:=walls[fromx  ,fromy  ];
                           end;
                           if b then begin
                                       came[tx,ty]:=true;
                                       mousesub (tx,ty,stack+1);
                                     end;
                         end;
                     end;
                 end;
        end;
    end;
  begin {mouse}
    successful:=false;
    for i:=1 to x do
      for j:=1 to y do
        came[i,j]:=false;
    came[fromx,fromy]:=true;
    mousesub (fromx,fromy,stack);
  end;
procedure warn;
  var ch,ch1:char;
  begin
    if soun then
      begin
        sound (400); delay(15); nosound;
      end;
    while keypressed do
      ReadAKey(ch,ch1);
  end;
procedure warna;
  begin
    sound (400); delay (30); nosound;
  end;
function min(x,y:real):real;
  begin
    if x<y then min:=x
           else min:=y
  end;
procedure ChangeKeys;
  var ch,ch1 :char;
      quit:boolean;
  procedure getkey(toput:integer);
    var same:boolean;
        i,j :integer;
        ch,ch1 :char;
    begin
      repeat
        ReadAKey (ch,ch1);
        if ch in ['A'..'Z'] then ch:=chr(ord(ch)+32);
        same:=false;
        for i:=1 to toput-1 do
          if (key[i].first=ch) and (key[i].next=ch1) then same:=true;
        if ch=#27 then
          begin
            same:=false;
            for i:=1 to 3 do
              for j:=succ(i) to 4 do
                if (key[i].first=key[j].first) and
                   (key[i].next=key[j].next)  then
                  begin
                    same:=true;
                    i:=3; j:=4;
                  end;
            if not same then quit:=true;
          end;
        if (ch=#0) and (ch1 in [#67,#68]) then same:=true;
        if same then warna;
        if (not same) and (not quit)
          then begin
                 with key[toput] do
                   begin
                     first:=ch; next:=ch1;
                   end;
                 writeln (print(ch,ch1));
               end;
      until (not same) or quit;
    end;
  procedure ChangeKey;
    begin
      quit:=false;
      fillscreen (0);
      gotoxy(1,1);
      writeln('Key-changing functions');
      writeln;
      writeln ('Type your own keys:');
      write ('Up   >_',^H); getkey(1);
      if quit then exit;
      write ('Down >_',^H); getkey(2);
      if quit then exit;
      write ('Left >_',^H); getkey(3);
      if quit then exit;
      write ('Right>_',^H); getkey(4);
    end;
  begin
    graphwindow (0,0,319+add*8,199);
    square (23,23,251,161,1);
    graphwindow (24,24,250,160);
    fillscreen (0);
    repeat
      gotoxy (1,1);
      writeln ('Key-changing functions');
      writeln;
      writeln ('Now keys:');
      writeln ('Up:    ',print(key[1].first,key[1].next));
      writeln ('Down:  ',print(key[2].first,key[2].next));
      writeln ('Left:  ',print(key[3].first,key[3].next));
      writeln ('Right: ',print(key[4].first,key[4].next));
      writeln; writeln;
      writeln ('Press <RETURN> to change,');
      writeln ('or <ESC> to go back.');
      repeat
        ReadAKey (ch,ch1);
      until ch in [#13,#27];
      if ch=#13 then begin
                       ChangeKey;
                       fillscreen(0);
                     end;
    until ch=#27;
    fillscreen (0);
  end;
procedure secret (code,hmkptr:integer);
  var i,j:integer;
  begin
    for i:=1 to 10 do
      with hmk[hmkptr,i] do
        for j:=1 to length(name) do
          name[j]:=chr(ord(name[j])+code);
  end;
{\\\\\\\\\\\\\\\\\\\\\play\\\\\\\\\\\\\\\\\\\\\\\\\\\\}
procedure play;
  var nowx,nowy,i,j,ii,eaten,tryd,mos1:integer;
      score,p,c:integer; {c is color}
      time,timelimit,r :real;
      ch,ch1   :char;
      wound :byte;
      rightkey,era,walked :boolean;
      state    :(lose,win,going,long,seen);
  procedure paint (x,y,color:integer);
    begin
      draw(step*x-4,step*y-4,step*x-4,step*y-2,color);
      draw(step*x-4,step*y-2,step*x-2,step*y-2,color);
      draw(step*x-2,step*y-2,step*x-2,step*y-4,color);
      draw(step*x-2,step*y-4,step*x-4,step*y-4,color);
      plot(step*x-3,step*y-3,0);
      if mazemt[x,y]=ATreasure then
        draw(step*x-1,step*y-4,step*x-1,step*y-1,0);
    end;
  procedure show(speed:integer);
    var i,j :integer;
        toquit :boolean;
        ch,ch1 :char;
    procedure WritePressMsg;
      begin
        gotoxy (36+add,23); write ('press');
        gotoxy (36+add,24); write ('  a  ');
        gotoxy (36+add,25); write (' key')
      end;
    begin
      if (not visible) and (not showed) then
        begin
          graphwindow (0,0,319+add*8,199);
          putpic(buffer,0,199);
          for i:=1 to x do
            for j:=1 to y do
              if not drawn[i,j] then
                drawmazebox(i,j);
          getpic (buffer,0,0,319+add*8,199);
          showed:=true;
        end;
      state:=seen;
      window (1,1,40+add,25);
      graphwindow (0,0,319+add*8,199);
      putpic (buffer,0,199);
      if speed=maxint then WritePressMsg;
      toquit:=false;
      i:=0;
      repeat
        i:=succ(i);
        paint (way[i].x,way[i].y,c);
        if speed=maxint
          then begin
                 if i<steps
                   then begin
                          ReadAKey (ch,ch1);
                          if (ch=#27) and (ch1='') then
                            toquit:=true;
                        end
               end
          else delay (speed);
        if (not WithFootPrint) and (i<>steps)
          then paint (way[i].x,way[i].y,0);
        if keypressed then begin
                             ReadAKey (ch,ch1);
                             if (ch=#27) and (ch1='') then toquit:=true;
                           end;
      until (i=steps) or toquit;
      if i=steps then begin
                       WritePressMsg;
                       ReadAKey (ch,ch1);
                     end;
      gotoxy (36+add,23); write (' ':5);
      gotoxy (38+add,24); write (' ');
      gotoxy (37+add,25); write (' ':3);
      graphwindow (24,24,250,160);
      window (5,5,31,20);
    end;
  procedure giveanswer;
    var ch,ch1 :char;
        stx,sty   :integer;
        speed,i,j :integer;
    begin
      graphwindow (0,0,319+add*8,199);
      square (23,23,251,161,1);
      graphwindow (24,24,250,160);
      fillscreen (0);
      gotoxy (1,3);
      writeln ('From where? _');
      writeln;
      writeln ('<CR>: from the start place');
      writeln ('"H" : from the place');
      writeln ('      you are now at');
      repeat
        ReadAKey(ch,ch1);
      until ch in [#13,'h','H',#27];
      if ch=#27 then exit;
      if ch=#13 then begin stx:=1;    sty:=y    end
                else begin stx:=nowx; sty:=nowy end;
      fillscreen (0);
      gotoxy (1,3);
      writeln ('At what speed? _');
      writeln;
      writeln ('<CR>: at normal speed');
      writeln ('"H" : at high speed');
      writeln ('"L" : at low speed');
      writeln ('"K" : don''t move until');
      writeln ('      any key pressed');
      repeat
        ReadAKey (ch,ch1); ch:=upcase(ch);
      until ch in [#13,'H','L','K',#27];
      if ch=#27 then exit;
      case ch of
       #13: speed:=30;
       'H': speed:=5;
       'L': speed:=100;
       'K': speed:=maxint;
      end;
      fillscreen (0);
      gotoxy (1,3); write ('With footprint?_');
      gotoxy (2,5); write ('(Y/N, <CR>=Y)');
      repeat
        ReadAKey (ch,ch1); ch:=upcase(ch);
      until ch in ['Y','N',#13,#27];
      if ch=#27 then exit;
      if ch='N' then WithFootPrint:=false
                else WithFootPrint:=true;
      fillscreen (0);
      gotoxy (1,3); write ('Please wait ...');
      mouse (stx,sty,1);
      gotoxy (1,3); write ('Press any key to start ...');
      ReadAKey (ch,ch1);
      if ch=#27 then exit;
      show (speed);
    end;
  procedure menu; {================MENU================}
    const funcs=4;
    var i      :integer;
        ch,ch1 :char;
    begin
      getpic (buffer,0,0,319+add*8,199);
      graphwindow (24,24,250,160);
      fillscreen (0);
      i:=1;
      repeat
        graphwindow (0,0,319+add*8,199);
        square (23,23,251,161,1);
        graphwindow (24,24,250,160);
        window (5,6,31,20);
        gotoxy (1,1);
        writeln ('***********MENU***********');
        writeln;
        writeln ('  1.Change keys');
        writeln ('  2.See the way out');
        write   ('  3.Sound on/off (Now:');
                      if soun then writeln ('ON )') else writeln ('OFF)');
        writeln ('  4.quit');
        gotoxy (1,9);
        writeln ('Use arrow keys to select,  or <CR> to start.');
        gotoxy (2,i+2);
        write ('');     {ctrl-p is a right arrow}
        ReadAKey (ch,ch1);
        if ch=#0 then begin
                        case ch1 of
                         #72,#75 : i:=pred(i);
                         #77,#80 : i:=succ(i);
                        end;
                        if i<1 then i:=funcs;
                        if i>funcs then i:=1;
                      end;
        if ch in ['1'..'4'] then begin
                                   i:=ord(ch)-48;
                                   ch:=#13;
                                 end;
        if ch=#27 then begin
                         i:=4;
                         ch:=#13;
                       end;
        if ch=#13 then begin
                         case i of
                          1: changekeys;
                          2: begin
                               giveanswer;
                               fillscreen(0);
                             end;
                          3: soun:=not soun;
                         end;
                       end;
      until (ch=#13) and (i=funcs);
      window (1,1,40+add,25);
      graphwindow (0,0,319+add*8,199);
      putpic (buffer,0,199);
    end;
  procedure askshow;
    begin
      border (1,17,36,20,1,''); window (1,1,40+add,25);
      gotoxy (3,18);
      writeln ('Do you want to see the way out?_');
      gotoxy (3,19);
      writeln ('   (Y/N, <CR>=Y)');
      repeat
        ReadAKey (ch,ch1); ch:=upcase(ch);
      until ch in ['Y','N',#13,#27];
      if ch=#27 then ch:='N';
      gotoxy (34,18); writeln (ch);
      if ch in ['Y',#13] then
        begin
          putpic (buffer,0,199);
          graphwindow (24,24,250,160);
          window (5,5,31,20);
          giveanswer;
          graphwindow (0,0,319+add*8,199);
          window (1,1,40+add,25);
          putpic (buffer,0,199);
        end;
    end;
  procedure chkprt(x,y:integer);
    begin
      if mazemt[x,y]=Apbox then
        drawmazebox (x,y);
    end;
  procedure chkeat(xx,yy:integer);
    begin
      if (mazemt[xx,yy]=ATreasure) then
        begin
          eaten:=succ(eaten);
          mazemt[xx,yy]:=normal;
          if eaten=treasures div 2 then
            draw (step*x,1,step*x,step-1,0);
          if soun then
            begin
              if eaten>=treasures div 2
                then
                  begin
                    sound(1000); delay(15); nosound;
                  end
                else
                  begin
                    sound(500); delay(15); nosound;
                  end;
            end;
        end;
    end;
  function CanGo(d,x,y:integer):boolean;
    begin
      if  (d=1) and wallh[x,y-1] or
          (d=2) and wallh[x,y]   or
          (d=3) and walls[x-1,y] or
          (d=4) and walls[x,y]
        then CanGo:=true
        else CanGo:=false;
    end;
  function nextdir(d:integer;goright:boolean):integer;
    begin
      if goright
        then
          case d of
           1:nextdir:=4;
           4:nextdir:=2;
           2:nextdir:=3;
           3:nextdir:=1;
          end
        else
          case d of
           1:nextdir:=3;
           3:nextdir:=2;
           2:nextdir:=4;
           4:nextdir:=1;
          end;
    end;
  begin
    randomize;
    eaten:=0;
    for mos:=1 to NumOfMons do
      begin
        monsd[mos]:=rnd(4)+1; goright[mos]:=boolean(rnd(2));
      end;
    if (mode=middle) and not bw
      then c:=3
      else c:=1;
    if visible then hmkptr:=1
               else hmkptr:=2;
    gotoxy (36+add,2);  write ('"F10"');
    gotoxy (37+add,3);  write ('for');
    gotoxy (36+add,4);  write ('menu');
    gotoxy (36+add,7);  write ('<ESC>');
    gotoxy (38+add,8);  write ('to');
    gotoxy (37+add,9);  write ('give');
    gotoxy (38+add,10); write ('up');
    gotoxy (37+add,12); write ('High');
    gotoxy (36+add,13); write ('Score');
    gotoxy (36+add,14); write (hmk[hmkptr,1].score:5);
    gotoxy (37+add,16); write ('Name');
    gotoxy (35+add,17); write (hmk[hmkptr,1].name:6);
    gotoxy (37+add,20); write ('TIME');
    gotoxy (40+add,21); write ('0');
    gotoxy (37+add,23); write ('LEFT');
    timelimit:=50.0*t;
    if not visible then timelimit:=timelimit*10;
    gotoxy (36+add,24); write (timelimit/100:5:0);
    nowx:=1; nowy:=y; time:=0;
    state:=going;
    wound:=0;
    if not visible then drawmazebox(nowx,nowy);
    paint (nowx,nowy,c);
    oldtime:=NowTime; oldtime1:=NowTime;
    walked:=true;
    beep:=false;
    repeat
      repeat
        newtime:=NowTime;
        if (newtime-oldtime>=10.0) or (newtime<oldtime) then
          begin
            oldtime:=newtime; time:=time+10.0;
          end;
        newtime1:=NowTime;
        if monster
           and ((newtime1-oldtime1>=ispeed*8) or (newtime1<oldtime1))
          then
            begin
              oldtime1:=newtime1; walked:=true;
              for mos:=1 to NumOfMons do
                begin
                  tryd:=nextdir(monsd[mos],goright[mos]);
                  while not CanGo(tryd,mox[mos],moy[mos]) do
                    tryd:=nextdir(tryd,not goright[mos]);
                  monsd[mos]:=tryd;
                  if not visible then fill:=true;
                  era:=true;
                  for mos1:=1 to NumOfMons do
                    if (mos<>mos1) and (mox[mos]=mox[mos1])
                       and (moy[mos]=moy[mos1])
                      then begin
                             era:=false;
                             mos1:=NumOfMons;
                           end;
                  if era then
                    begin
                      norec:=true;
                      drawmazebox (mox[mos],moy[mos]);
                      norec:=false;
                    end;
                  fill:=false;
                  mox[mos]:=mox[mos]+dx[monsd[mos]];
                  moy[mos]:=moy[mos]+dy[monsd[mos]];
                  paint(nowx,nowy,1);
                  drawmonster (mox[mos],moy[mos]);
                end;
            end;
        if (abs(time/100-trunc(time/100+1e-7))<1e-7)
           or (time>timelimit)
          then begin
                 gotoxy (37+add,21);
                 write (time/100:4:0);
                 gotoxy (36+add,24);
                 write (abs(timelimit-time)/100:5:0);
               end;
        if time>timelimit then state:=long;
        if (mazemt[nowx,nowy]=normal) and not ((nowx=1) and (nowy=y))
           and monster and walked
          then
            for mos:=1 to NumOfMons do
              if (nowx=mox[mos]) and (nowy=moy[mos])
                then
                  begin
                    inc(wound); walked:=false;
                    draw(280+wound*10+add*8,197,
                         286+wound*10+add*8,197,1);
                    draw(280+wound*10+add*8,198,
                         286+wound*10+add*8,198,1);
                    if soun then music('s300 o2 l1 1');
                    for ii:=1 to 10 do
                      begin
                        time:=time+100.0;
                        if time>timelimit then
                          begin
                            time:=timelimit;
                            state:=long;
                            ii:=10;
                          end;
                        gotoxy (37+add,21);
                        write (time/100:4:0);
                        gotoxy (36+add,24);
                        write (abs(timelimit-time)/100:5:0);
                        if soun then music('s100 l1 o3 1');
                      end;
                    if wound=3 then state:=lose;
                    mos:=NumOfMons;
                  end;
      until keypressed or (state in [long,lose]);
      if keypressed then ReadAKey(ch,ch1)
                    else ch:='';
      if (ch=#0) and (ch1=#68) then
        begin
          nosound; beep:=false;
          menu;
        end;
      if (ch>='A') and (ch<='Z') then ch:=chr(ord(ch)+32);
      p:=1; rightkey:=false;
      repeat
        if (ch=key[p].first) and (ch1=key[p].next)
          then begin
                 rightkey:=true;
               end;
        p:=succ(p);
      until (p>4) or rightkey;
      p:=pred(p);
      if (ch=#27) and (ch1='') then state:=lose;
      if not rightkey
        then begin
               if (state=going) and
                  not (((ch=#0) and (ch1=#68)))
                 then warn;
             end
        else begin
               case p of
        {up}    1  : begin
                       if wallh[nowx,nowy-1]
                         then begin
                                paint(nowx,nowy,0);
                                chkprt(nowx,nowy);
                                nowx:=nowx+dx[1]; nowy:=nowy+dy[1];
                                if not visible
                                  then drawmazebox(nowx,nowy);
                                paint(nowx,nowy,c);
                                chkeat(nowx,nowy);
                              end
                         else warn;
                     end;
        {down}  2  : begin
                       if wallh[nowx,nowy]
                         then begin
                                paint(nowx,nowy,0);
                                chkprt(nowx,nowy);
                                nowx:=nowx+dx[2]; nowy:=nowy+dy[2];
                                if not visible
                                  then drawmazebox(nowx,nowy);
                                paint(nowx,nowy,c);
                                chkeat(nowx,nowy);
                              end
                         else warn;
                     end;
        {left}  3  : begin
                       if walls[nowx-1,nowy]
                         then begin
                                paint(nowx,nowy,0);
                                chkprt(nowx,nowy);
                                nowx:=nowx+dx[3]; nowy:=nowy+dy[3];
                                if not visible
                                  then drawmazebox(nowx,nowy);
                                paint(nowx,nowy,c);
                                chkeat(nowx,nowy);
                              end
                         else warn;
                     end;
        {right} 4  : begin
                       if walls[nowx,nowy]
                         then begin
                                paint(nowx,nowy,0);
                                chkprt(nowx,nowy);
                                nowx:=nowx+dx[4]; nowy:=nowy+dy[4];
                                if not visible
                                  then drawmazebox(nowx,nowy);
                                paint(nowx,nowy,c);
                                chkeat(nowx,nowy);
                              end
                         else warn;
                     end;
               end;
               if (nowx=x) and (nowy=1) and (eaten>=treasures div 2)
                 then state:=win;
             end;
    until state<>going;
    delay (21); nosound;
    case state of
     win:  begin
             if soun then
               music ('l150 o3 5 o4 1 o3 5 o4 300 1');
             border (3,11,35,22,1,'');
             window (1,1,40+add,25);
             gotoxy (8,13); write ('Congratulations!');
             gotoxy (10,15); write ('You win !!');
             diffi:=diffi-(treasures+1) div 2;
             if monster then diffi:=diffi-(protect+1) div 2;
             if diffi<1 then diffi:=1;
             r:=50.0*sqrt(1.0*diffi*diffi*diffi)
                *min(x,y)/time;
             for i:=1 to eaten do
               r:=r*1.1;
             for i:=1 to NumOfMons do
               r:=r*1.2;
             if monster then
               r:=r*6.5*exp(0.4*ln(40/ispeed)/(protect+1))
                  /sqrt(1.0*diffi*diffi*diffi)*exp(0.9*ln(1.0*diffi));
             score:=round(r);
             if not visible then score:=score*5;
             if visible then hmkptr:=1
                        else hmkptr:=2;
             gotoxy (10,18);
             write ('Your score:',score);
             if score>hmk[hmkptr,10].score then
               begin
                 i:=10;
                 while score>hmk[hmkptr,pred(i)].score do
                   begin
                     hmk[hmkptr,i]:=hmk[hmkptr,pred(i)];
                     i:=pred(i);
                   end;
                 if soun then
                   music ('0135 o5 l900 1');
                 gotoxy (6,20);
                 writeln ('New high score!!! (No. ',i,')');
                 gotoxy (6,21);
                 write   ('...Your name:');
                 readstr (hmk[hmkptr,i].name,6,NoHide);
                 hmk[hmkptr,i].score:=score;
                 if usefile then
                   begin
                     secret (-scrcode,1);
                     secret (-scrcode,2);
                     {$I-}
                     rewrite (hmkfile);
                     if IOResult=0 then
                       write (hmkfile,hmk[1],hmk[2]);
                     i:=IOResult;
                     close (hmkfile);
                     i:=IOResult;
                     {$I+}
                     secret (scrcode,1);
                     secret (scrcode,2);
                   end;
               end;
           end;
     lose: begin
             getpic (buffer,0,0,319+add*8,199);
             if soun then
               music ('1 o3 l50 765432 l600 1');
             border (10,14,27,16,1,'');
             window (1,1,40+add,25);
             gotoxy (15,15); writeln ('You lose!');
             askshow;
           end;
     long: begin
             getpic (buffer,0,0,319+add*8,199);
             if soun then
               music ('l150 1110 o3 l400 1');
             border (10,14,32,16,1,''); window (1,1,40+add,25);
             gotoxy (15,15); write ('Time passed.');
             askshow;
           end;
     seen: begin
             border (1,13,36,19,2,''); window (1,1,40+add,25);
             gotoxy (3,15);
             writeln ('You have seen the way out, so you');
             gotoxy (2,16);
             writeln ('can''t go on playing this maze.');
           end;
    end;
  end;
procedure setmode;
  begin
    if mode=middle
      then if bw then graphmode
                 else graphcolormode
      else begin
             textmode (c80);
             hires;
             if bw then hirescolor (15)
                   else hirescolor (13);
             if blb then graphbackground(0);
           end;
    palette(NowPalette);
  end;
procedure startplaying;
  var ch,ch1:char;
      i,j,k:integer;
      interrupted:boolean;
  begin
    setmode;
    window (1,1,40+add,25);
    graphwindow (0,0,319+add*8,199);
    draw (x*step,0,x*step,step*y,c);
    draw (x*step,step*y,0,y*step,c);
    draw (0,y*step,0,0,c);
    draw (0,0,x*step,0,c);
    graphwindow (1,1,x*step-1,y*step-1);
    if mode=high
      then fillscreen (1)
      else fillscreen (2);
    graphwindow(0,0,319+add*8,199);
    draw (0,step*(y-1)+1,0,step*y-1,0);
    if treasures<2 then
      draw (step*x,1,step*x,step-1,0);
    for i:=0 to x+1 do
      for j:=0 to y+1 do
        begin
          maze[i,j]:=false;
          if (i*j=0) or (i=x+1) or (j=y+1) then maze[i,j]:=true;
          walls[i,j]:=false;
          wallh[i,j]:=false;
        end;
    pass:=1;
    t:=x*y;
    if x=1 then rx:=1
           else rx:=random(x-1)+1;
    if y=1 then ry:=1
           else ry:=random(y-1)+1;
    maze[rx,ry]:=true;
    ch:='';
    walk (rx,ry,random(4)+1);
    mouse (1,y,1); diffi:=steps;
    for i:=1 to x do
      for j:=1 to y do
        drawn[i,j]:=false;
    for i:=1 to x do
      for j:=1 to j do
        mazemt[i,j]:=normal;
    for i:=1 to treasures do
      begin
        repeat
          j:=rnd(x)+1; k:=rnd(y)+1;
        until (mazemt[j,k]=normal) and
              ((j<>1) or (k<>y)) and ((j<>x) or (k<>1));
        mazemt[j,k]:=ATreasure;
        drawmazebox(j,k);
      end;
    if monster then
      begin
        for i:=1 to protect do
          begin
            repeat
              j:=rnd(x)+1; k:=rnd(y)+1;
            until (mazemt[j,k]=normal) and
                  ((j<>1) or (k<>y)) and ((j<>x) or (k<>1));
            mazemt[j,k]:=Apbox;
            drawmazebox(j,k);
          end;
        for mos:=1 to NumOfMons do
          repeat
            mox[mos]:=rnd(x)+1; moy[mos]:=rnd(y)+1;
          until (mazemt[mox[mos],moy[mos]]=normal)
                and not((mox[mos]=1) and (moy[mos]=y));
      end;
    ch:=''; ch1:='';
    if keypressed then ReadAKey(ch,ch1);
    if ch=#27
      then
        begin
          gotoxy (3,8); write ('*** Interrupted ***');
          warna;
        end
      else
        begin
          interrupted:=false;
          if visible then
            for i:=1 to x do
              for j:=1 to y do
                begin
                  drawmazebox(i,j);
                  if keypressed then
                    begin
                      ReadAKey(ch,ch1);
                      if ch=#27 then
                        begin
                          interrupted:=true; i:=x; j:=y;
                          gotoxy (3,8);
                          write ('*** Interrupted ***');
                          warna;
                        end;
                    end;
                end;
          if not interrupted then
            begin
              if monster then
                for mos:=1 to NumOfMons do
                  drawmonster(mox[mos],moy[mos]);
              showed:=false;
              play;
            end;
        end;
  end;
procedure ToStart;
  var i:integer;
      ch,ch1:char;
  begin
    setmode;
    randomize;
    repeat
      draw (189+add*8,0,189+add*8,105,1);
      draw (189+add*8,105,319+add*8,105,1);
      window (25+add,1,40+add,13);
      graphwindow (190+add*8,0,319+add*8,104);
      fillscreen (0);
      gotoxy (1,2);
      writeln ('* High Scores *');
      if visible then hmkptr:=1
                 else hmkptr:=2;
      for i:=1 to 10 do
        with hmk[hmkptr,i] do
          writeln (name:7,score:7);
      graphwindow (0,0,319+add*8,199);
      if mode=high then i:=1
                   else i:=2;
      square (1,172,308,196,i);
      graphwindow (2,173,307,195);
      fillscreen (0);
      window (1,1,40+add,25);
      graphwindow(0,0,319+add*8,199);
      gotoxy (2,23);
      write ('Press <RETURN> to continue,');
      gotoxy (2,24);
      write ('or <ESC> to return to the main menu.');
      repeat
        ReadAKey (ch,ch1);
      until (ch=#13) or ((ch=#27) and (ch1=''));
      if ch=#13 then startplaying;
    until ch<>#13;
  end;
procedure ChangeMazeSize;
  var ix,iy:integer;
  begin
    tc(14,7); bg(4,0);
    border(3,6,36,15,1,' Change Maze Size ');
    tc(10,15); gotoxy(1,7);
    writeln (' <RETURN> - Keep old size');
    write   (' <ESC>    - Abort');
    tc(15,15);
    window (5,8,35,11);
    repeat
      gotoxy (1,1);
      ix:=x;
      write ('Width of the maze(5-',nmx-1,')='); clreol;
      readstr (c1,2,hide);
      val (c1,ix,retcode);
      if retcode<>0 then ix:=1000;
      if (c1='') or quitinp then ix:=x;
    until ix in [5..nmx];
    x:=ix;
    if quitinp then exit;
    repeat
      gotoxy (1,2);
      iy:=y;
      write ('Height of the maze(5-',nmy-1,')='); clreol;
      readstr (c1,2,hide);
      val (c1,iy,retcode);
      if retcode<>0 then iy:=1000;
      if (c1='') or quitinp then iy:=y;
    until iy in [5..nmy];
    y:=iy;
  end;
procedure ChangeScreenMode;
  var ch,ch1 :char;
  begin
    if mode=high then begin
                        mode:=middle;
                        add:=0;
                        nmx:=46;
                        if x>45 then x:=45;
                      end
               else begin
                      mode:=high;
                      add:=40;
                      nmx:=99;
                    end;
  end;
procedure Set_Monster_Treasure;
  var ch,ch1:char;
      bf,chosen:integer;
  procedure setspeed;
    begin
      tc(13,15); bg(6,0);
      border (13,12,35,20,1,'Set Monster Speed');
      tc(0,7);
      repeat
        gotoxy(1,2);
        write ('Monster Speed(1-100):');
        clreol;
        readstr (c1,3,hide);
        val (c1,bf,retcode);
        if retcode<>0 then bf:=maxint;
        if (c1='') or quitinp then bf:=mspeed;
      until (bf>=1) and (bf<=100);
      mspeed:=bf;
      ispeed:=round(40.0/(0.4*(mspeed-1)+1));
      if ispeed<1 then ispeed:=1;
      if ispeed>40 then ispeed:=40;
    end;
  procedure InputMons;
    begin
      tc(12,15); bg(1,0);
      border (12,6,40,10,0,'Set Monsters');
      tc(14,7);
      repeat
        window(14,8,39,8);
        clrscr;
        write ('How many monsters(0-',maxmons,')?');
        clreol;
        window (14,8,40,8); gotoxy(24,1);
        readstr (c1,1,hide);
        val (c1,bf,retcode);
        if retcode<>0 then bf:=maxint;
        if (c1='') or quitinp then bf:=NumOfMons;
      until bf in [0..maxmons];
      NumOfMons:=bf;
      if NumOfMons=0 then monster:=false
                     else monster:=true;
    end;
  procedure InputPrt;
    begin
      tc(10,15); bg(2,0);
      border (17,6,37,13,1,'Set Protect-boxes');
      tc(14,7);
      repeat
        gotoxy (1,2);
        write ('How many protected-boxes(0-',maxprt,'):');
        clreol;
        readstr (c1,2,hide);
        val (c1,bf,retcode);
        if retcode<>0 then bf:=maxint;
        if (c1='') or quitinp then bf:=protect;
      until bf in [0..maxprt];
      protect:=bf;
    end;
  procedure InputTrea;
    begin
      tc(14,15); bg(4,0);
      border (6,11,28,16,2,'Set Treasures');
      repeat
        clrscr;
        write ('How many treasures (0-',maxtrea,')?');
        readstr (c1,1,hide);
        val (c1,bf,retcode);
        if retcode<>0 then bf:=maxint;
        if (c1='') or quitinp then bf:=treasures;
      until bf in [0..maxtrea];
      treasures:=bf;
    end;
  procedure setbg(i:integer);
    begin
      if i=chosen
        then begin
               bg(13,0);
               if bw then textcolor(15);
             end
        else begin
               bg(3,7);
               if bw then textcolor(0);
             end;
    end;
  begin
    tc(0,0); bg(3,7);
    border (1,5,37,18,1,'Set Monsters & Treasures');
    chosen:=1;
    repeat
      tc(0,15); bg(3,7);
      gotoxy (1,3);
      setbg(1); write ('Number of monsters(0-',maxmons,
                       ')---------  ',NumOfMons);
      setbg(2); write ('Number of protected-boxes(0-',maxprt:2,
                       ')- ',protect:2);
      setbg(3); write ('Number of treasures(0-',maxtrea,
                       ')--------  ',treasures);
      setbg(4); write ('Monster speed(1-100) -----------',mspeed:3);
      setbg(0); writeln;
      writeln ('   : Move cursor');
      writeln (#27,#26,'   : Dec/Inc value');
      writeln ('<CR> : Input value');
      write   ('<ESC>: Exit');
      tc(3,7); write (' ',^H);
      keeptext(2);
      ReadAKey(ch,ch1);
      case ch1 of
       #72 : chosen:=pred(chosen);
       #80 : chosen:=succ(chosen);
      end;
      if chosen<1 then chosen:=4;
      if chosen>4 then chosen:=1;
      if (ch=#13) or (ch1 in [#75,#77]) then
        case chosen of
         1: begin
              if ch<>#13
                then
                  begin
                    if ch1<>#75
                      then NumOfMons:=succ(NumOfMons)
                      else NumOfMons:=pred(NumOfMons);
                    if NumOfMons>maxmons then NumOfMons:=0;
                    if NumOfMons<0 then NumOfMons:=maxmons;
                    if NumOfMons=0 then monster:=false
                                   else monster:=true;
                  end
                else InputMons;
            end;
         2: begin
              if ch<>#13
                then
                  begin
                    if ch1<>#75
                      then protect:=succ(protect)
                      else protect:=pred(protect);
                    if protect>maxprt then protect:=0;
                    if protect<0 then protect:=maxprt;
                  end
                else
                  InputPrt;
            end;
         3: begin
              if ch<>#13
                then
                  begin
                    if ch1<>#75
                      then treasures:=succ(treasures)
                      else treasures:=pred(treasures);
                    if treasures>maxtrea then treasures:=0;
                    if treasures<0 then treasures:=maxtrea;
                  end
                else InputTrea;
            end;
         4: begin
              if ch<>#13
                then
                  begin
                    if ch1<>#75
                      then mspeed:=mspeed+10
                      else mspeed:=mspeed-10;
                    if mspeed>100 then mspeed:=mspeed-100;
                    if mspeed<1 then mspeed:=mspeed+100;
                    ispeed:=round(40.0/(0.4*(mspeed-1)+1));
                    if ispeed<1 then ispeed:=1;
                    if ispeed>40 then ispeed:=40;
                  end
                else
                  setspeed;
            end;
        end;
      restore(2);
      window (2,6,36,17);
    until ch=#27;
  end;

procedure writecfg;
  var io,i:integer;
      i1,i2,i3,i4,i5,i6:integer;
  begin
    tc(0,15); bg(3,0);
    border (4,16,37,18,1,'');
    write (' Saving configuration file...');
    assign (cfg,cfgfile);
    {$I-} rewrite(cfg);
    case IOResult of
     150: ReportErr (' The disk is write-protected.');
     152: ReportErr ('Disk is not ready'+drv);
     0:   begin
            i1:=ord(soun); i2:=ord(bw); i3:=ord(visible);
            i4:=ord(monster); i5:=ord(mode); i6:=ord(blb);
            write (cfg,i1,i2,i3,i4,protect,treasures,mspeed,
                   NumOfMons,NowPalette,ispeed,x,y,i5,add,nmx,nmy,i6);
            io:=IOResult;
            for i:=1 to 4 do
              begin
                i1:=ord(key[i].first); i2:=ord(key[i].next);
                write (cfg,i1,i2); io:=IOResult;
              end;
          end;
     else ReportErr('  Unable to write on disk '+drive+'.');
    end;
    close(cfg); io:=IOResult; {$I+}
  end;
procedure readcfg;
  var io,i:integer;
      i1,i2,i3,i4,i5,i6:integer;
  procedure initpara;
    var ch,ch1:char;
        nextgo:boolean;
    procedure normal;
      begin
        textcolor(15); textbackground(0);
      end;
    procedure inverse;
      begin
        textcolor(0); textbackground(15);
      end;
    begin
      textmode(bw40);
      nextgo:=false;
      bw:=false;
      textbackground(0); textcolor(15);
      gotoxy (5,10); writeln ('Please choose displaying mode:');
      repeat
        gotoxy (8,12);
        if bw then normal else inverse;
        write('Color');
        gotoxy (22,12);
        if bw then inverse else normal;
        write('Black/White');
        textcolor(0); textbackground(0); write(' '^H);
        if nextgo then begin
                         ch:=#13; ch1:=#0;
                       end
                  else ReadAKey(ch,ch1);
        if (ch in [#9,' ']) or ((ch=#0) and (ch1 in [#75,#77]))
          then bw:=not bw;
        if (bw and (upcase(ch)='C')) or ((not bw) and (upcase(ch)='B'))
          then begin
                 bw:=not bw; nextgo:=true;
               end;
      until ch=#13;
      soun:=true; visible:=true; monster:=true;
      protect:=6; treasures:=5; mspeed:=30; NumOfMons:=1;
      NowPalette:=0; palette(NowPalette);
      ispeed:=round(40.0/(0.4*(mspeed-1)+1));
      if ispeed<1 then ispeed:=1;
      if ispeed>40 then ispeed:=40;
      randomize;
      x:=20; y:=20;
      key[1].first:=#0; key[1].next:=#72; {up arrow}
      key[2].first:=#0; key[2].next:=#80; {down arrow}
      key[3].first:=#0; key[3].next:=#75; {left arrow}
      key[4].first:=#0; key[4].next:=#77; {right arrow}
      mode:=middle; add:=0;
      nmx:=46; nmy:=34;
      if bw then textmode(bw40) else textmode(c40);
      writecfg;
    end;
  begin
    io:=0;
    assign (cfg,cfgfile);
    {$I-} reset(cfg);
    if IOResult=0
      then
        begin
          textmode(bw40); tc(0,0); bg(7,7);
          gotoxy (1,24);
          write (' Loading configuration file...'); clreol;
          read (cfg,i1,i2,i3,i4,protect,treasures,mspeed,
                NumOfMons,NowPalette,ispeed,x,y,i5,add,nmx,nmy,i6);
          io:=io+IOResult;
          soun:=boolean(i1);    bw:=boolean(i2);    visible:=boolean(i3);
          monster:=boolean(i4); mode:=modetype(i5);
          for i:=1 to 4 do
            begin
              read (cfg,i1,i2); io:=io+IOResult;
              key[i].first:=chr(i1); key[i].next:=chr(i2);
            end;
          if io<>0 then initpara;
        end
      else
        begin
          initpara;
        end;
    close(cfg); io:=IOResult; {$I+}
  end;
procedure mainmenu; {=================Main Menu==================}
  const funcs=9;
  var i,io :integer;
      ch,ch1,ch2,ch3,ch4 :char;
      quit,nextgo :boolean;
      ff:file;
      attr:word;
      st,com:string[255];
  procedure setbg (num:integer);
    begin
      if i=num then begin
                      bg(5,7); tc(7,0);
                    end
               else begin
                      bg(1,0); tc(7,15);
                      clreol;
                    end;
      if num=0 then tc(3,7);
    end;
  procedure settextmode;
    begin
      if bw then textmode (bw40)
            else textmode (C40);
      clrscr;
    end;
  procedure writemsg (i:integer);
    begin
      gotoxy(1,13); tc(10,7); bg(4,0);
      case i of
       2: write ('Current size: ',x,'*',y);
       4: begin
            write ('Current mode: ');
            if mode=high then write (' High ')
                         else write ('Middle');
          end;
       5: begin
            write ('Now sound: ');
            if soun then write ('ON ')
                    else write ('OFF');
          end;
       6: begin
            write ('Current mode: ');
            if bw then write (' B/W ')
                  else write ('COLOR');
          end;
       7: begin
            write ('Current mode: ');
            if visible then write ('visible')
                       else write ('invisible');
          end;
       8: begin
            if monster
              then
                write (NumOfMons,' monster(s),x=',protect:2,
                        ',v=',mspeed:2)
              else
                write ('no monster');
            write (',·=',treasures);
          end;
      end;
      clreol;
      writeln;
      bg(2,0); tc(0,15); clreol;
      write ('[1]   [2] ',x:2,'*',y:2,' [3]   [4] ');
      if mode=high then writeln('H') else writeln ('M');
      write ('[5] ');
      if soun then write (#14) else write ('_');
      write (' [6] ');
      if bw then write ('B/W  ') else write ('Color');
      write (' [7] ');
      if visible then write('V') else write('I');
      write (' [8] ');
      if monster then write (#1,'/',protect)
                 else write ('_   ');
      write ('/',treasures);
      clreol;
    end;
  procedure IOIdemo;
    var i,j:integer;
        s:string;
    procedure HideCursor;
      begin
        tc(1,0); write(' ',^H);
      end;
    procedure GiveMsg;
      begin
        tc(30,31); write('  Scroll Lock=ON');
        HideCursor; delay(1500);
        gotoxy(1,1);
        tc(30,31); write('     No Sound   ');
        HideCursor; delay(1500);
        tc(14,15); gotoxy(1,1); clreol;
      end;
    procedure writeIOI;
      var i,c:integer;
      begin
        repeat
          c:=random(16);
        until c in [0,2..8,10..15];
        gotoxy(1,1);
        tc(c,15);
        writeln(' III   OOO   III');
        for i:=1 to 4 do
          writeln('  I   O   O   I ');
        writeln(' III   OOO   III');
        HideCursor;
      end;
    begin
      MusicIntr:=true;
      tc(14,15); bg(1,0);
      for i:=1 to 8 do
        BorderLine(2+i,3+i,38-i,21-i);
      clreol;
      HideCursor;
      if (mem[$0000:$0417] shr 4) mod 2=1
        then
          GiveMsg
        else
          begin
            music('s500 o3 l1 212 l3 4 l2 3 l2 3 l4 2 l1 0');
            music('s600 o3 l1 212 l3 4 l2 3 l2 3 l4 2 l1 0');
          end;
      tc(14,15); bg(1,0);
      gotoxy(1,1); clreol;
      write('>');
      readstr(s,3,hide);
      for i:=1 to length(s) do
        s[i]:=upcase(s[i]);
      if s='IOI' then
        begin
          tc(14,15); bg(1,0);
          border(6,7,34,17,2,'The 2nd IOI --- 1990.7.');
          window(11,9,29,15);
          writeIOI;
          for i:=1 to 2 do
            begin
              if (mem[$0000:$0417] shr 4) mod 2<>1
                then
                  music
                    ('s300 o4 l2 3 l1 321 o3 760 '+
                     'l2 6 l1 o4 1 o3 765632 l4 30')
                else delay(200);
              writeIOI;
            end;
          for i:=1 to 2 do
            begin
              if (mem[$0000:$0417] shr 4) mod 2<>1
                then
                  music
                    ('s300 o4 l2 2 l1 221 o3 l2 4 '+
                     'l1 46 o4 s450 l1 32 s300 l1 1 o3 l2 4')
                else delay(200);
              writeIOI;
              if (mem[$0000:$0417] shr 4) mod 2<>1
                then
                  music
                    ('s300 o3 l1 6 o4 1 o3 l3 7 '+
                     'l1 65 l2 6 l1 5 l4 60')
                else delay(200);
              writeIOI;
            end;
        end;
      restore(1);
      window (4,5,36,19);
      tc(14,15); bg(1,0);
      MusicIntr:=false;
    end;
  procedure checkIOI;
    var ch2,ch3:char;
    begin
      ReadAKey(ch2,ch3);
      if upcase(ch2)='O'
        then
          begin
            ReadAKey(ch2,ch3);
            if upcase(ch2)='I'
              then
                begin
                  repeat
                  until keypressed or (mem[$0000:$0417] mod 8=7);
                  if keypressed
                    then ReadAKey(ch,ch1)
                    else
                      begin
                        IOIdemo;
                        ch:=#1; ch1:=#0;
                      end;
                end
              else
                begin
                  ch:=ch2; ch1:=ch3;
                end;
          end
        else
          begin
            ch:=ch2; ch1:=ch3;
          end;
    end;
  begin
    i:=1;
    quit:=false; nextgo:=false;
    if bw then graphmode
          else graphcolormode;
    repeat
      settextmode;
      gotoxy(1,1); tc(0,0); bg(0,0); write(' ');
      tc(14,15); bg(1,0);
      border(2,3,38,21,0,' M A Z E -- VER 6.21 ');
      gotoxy (14,18);
      write ('ÉÍÍCopyright 1991.4.24Í¹');
      gotoxy (14,19); write ('Ê');     {  ¼   »   È   É   Í   º   Ä   }
      gotoxy (23,19);                  {  188 187 200 201 205 186 196 }
      write ('by Yang Cheng');
      tc(10,15);
      gotoxy (3,19); write ('[?]-HELP');
      window (4,5,36,19);
      tc(11,15);
      gotoxy (4,1);
      writeln ('******** Main Menu ********');
      repeat
        gotoxy (1,3);
        setbg(1); writeln (' 1.Start playing ');
        setbg(2); writeln (' 2.Change maze size ');
        setbg(3); writeln (' 3.Change keys ');
        setbg(4); writeln (' 4.Change screen mode ');
        setbg(5); writeln (' 5.Sound ON/OFF ');
        setbg(6); writeln (' 6.Change Displaying mode ');
        setbg(7); writeln (' 7.Change way mode ');
        setbg(8); writeln (' 8.Set monsters & treasures ');
        setbg(9); writeln (' 9.Quit this game ');
        writemsg(i);
        gotoxy(1,1);
        tc (1,0); bg(1,0); write (' ',^H);
        keeptext(1);
        window (4,5,36,19);
        if nextgo
          then
            begin
              nextgo:=false;
              ch:=#13;
            end
          else
            begin
              ReadAKey (ch,ch1);
              if upcase(ch)='I' then
                checkIOI;
            end;
        if ch=#0 then
          begin
            case ch1 of
             #72,#75 : i:=pred(i);
             #77,#80 : i:=succ(i);
             #60     : begin
                         writecfg;
                         restore(1);
                         window (4,5,36,19);
                       end;
            end;
            if i<1 then i:=funcs;
            if i>funcs then i:=1;
          end;
        if ch='?' then
          begin
            help;
            restore(1);
            window (4,5,36,19);
          end;
        if ch in ['1'..'9'] then begin
                                   i:=ord(ch)-48;
                                   nextgo:=true;
                                 end;
        if ch=#27 then begin
                         i:=funcs;
                         nextgo:=true;
                       end;
        if ch1=#24 then     { Alt-O : OS shell }
          begin
            com:=GetEnv('COMSPEC');
            assign (ff,com);
            GetFAttr(ff,attr);
            case DosError of
             152: ReportErr('Disk is not ready in drive '+com[1]+'.');
               2: ReportErr('  Can''t find '+com);
               0:
                 begin
                   textmode (c80);
                   tc(7,7); bg(0,0); clrscr;
                   writeln ('Type EXIT to return to MAZE 6.21......');
                   SwapVectors;
                   exec (com,'');
                   SwapVectors;
                   settextmode;
                   case DosError of
                      2: ReportErr('  Can''t find '+com);
                      8: ReportErr('     Not Enough Memory.');
                    152: ReportErr('Disk is not ready in drive '+com[1]+'.');
                      0: begin
                           getdir (0,st); io:=IOResult; io:=DosError;
                           drive:=upcase(st[1]);
                           drv:=' in drive '+drive+'.';
                         end;
                    else ReportErr(' Unable to read from disk '+drive+'.');
                   end;
                 end;
             else ReportErr(' Unable to read from disk '+drive+'.');
            end;
            restore(1);
            window (4,5,36,19);
          end;
        if ch=#13 then
          case i of
           1: begin
                tc(11,15);
                ToStart;
                if bw then graphmode
                      else graphcolormode;
                settextmode;
                restore(1);
                window (4,5,36,19);
              end;
           2: begin
                ChangeMazeSize;
                restore(1);
                window (4,5,36,19);
              end;
           3: begin
                tc(11,15);
                if bw then graphmode
                      else graphcolormode;
                palette(NowPalette);
                graphwindow (24,24,250,160);
                window (5,5,31,20);
                ChangeKeys;
                if bw then graphmode
                      else graphcolormode;
                settextmode;
                restore(1);
                window (4,5,36,19);
              end;
           4: ChangeScreenMode;
           5: soun:=not soun;
           6: begin
                bw:=not bw;
                tc(13,15);
              end;
           7: visible:=not visible;
           8: begin
                Set_Monster_Treasure;
                restore(1);
                window (4,5,36,19);
              end;
           9: begin
                bg(3,0); tc(9,15);
                border (13,12,35,14,1,'');
                write (' Are you sure(Y/N)?');
                ReadAKey (ch2,ch1);
                if upcase(ch2)='Y'
                  then quit:=true
                  else
                    begin
                      restore(1);
                      window (4,5,36,19);
                    end;
              end;
          end;
      until (ch=#13) and (i=6) or quit;
    until quit;
    if bw then textmode(bw80)
          else textmode(C80);
    tc(7,7); bg(0,0);
    clrscr;
    gotoxy (10,10); tc(13,15);
    writeln ('Goodbye!');
    gotoxy (1,20);
  end;
procedure cover;
  var ch,ch1:char;
      i:integer;
  begin
    if bw then textmode (bw40) else textmode(c40);
    tc(14,15); bg(4,0);
    border (1,2,40,21,1,'');
    tc(13,0); bg(1,7);
    border(2,3,39,11,1,'');
    tc(13,0);  writeln (' M     M     A     ZZZZZZZ  EEEEEEE');
    tc(10,0);  writeln (' MM   MM   AA AA   Z   ZZ   EE     ');
    tc(11,0);  writeln (' M M M M  AA   AA     ZZ    EEEEEE ');
    tc(12,0);  writeln (' M  M  M  AAAAAAA    ZZ     EEEEEE ');
    tc(15,0);  writeln (' M     M  AA   AA   ZZ   Z  EE     ');
    tc(14,0);  writeln (' M     M  AA   AA  ZZZZZZZ  EEEEEEE');
    window (2,3,39,20);
    gotoxy (10,12);
    textbackground(0); if bw then textcolor(15);
    write ('** Version  6.21 **');
    gotoxy (11,14);
    bg(3,0); tc(17,31);
    write ('Welcome to play !');
    gotoxy (7,16);
    bg(2,15); tc(0,0);
    writeln ('Press any key to start...');
    tc(4,0);  bg(4,0);
    gotoxy (1,17); write (' '); gotoxy (1,17);
    MusicIntr:=true;
    repeat
      music ('s300 l1 o3 5 o4 1 l3 3 l1 1 o3 5 o4 136 l4 5 l2 3');
      music ('s300 l1 11 l3 1 l1 o3 7 o4 1 o3 7 o4 13 l5 2');
      music ('s300 l1 o3 05 o4 1 l3 3 l1 1 o3 5 o4 1 o3 7 h460 l4 6');
      music ('s300 o4 l2 4 l1 2 o3 7 o4 l3 1 l1 5 h740 54');
      music ('s300 l1 o3 7 o4 l5 1 l1 0 l8 0');
    until keypressed;
    ReadAKey (ch,ch1);
    MusicIntr:=false;
    gotoxy (1,1);
    bg(4,0); tc(4,0);
    for i:=1 to 19 do
      begin
        InsLine;
        delay (60);
      end;
  end;
procedure InitHmk;
  var i,j:integer;
  begin
    for j:=1 to 2 do
      begin
        hmk[j,0].score:=maxint;
        for i:=1 to 10 do
          with hmk[j,i] do
            begin
              name:='......';
              score:=0;
            end;
      end;
  end;
procedure GetHighScore;
  var st:string[255];
      ch,ch1:char;
      retcode,i,io :integer;
  begin
    usefile:=true;
    getdir (0,st);
    drive:=upcase(st[1]); drv:=' in drive '+drive+'.';
    io:=IOResult; io:=DosError;
    if upcase(st[1]) in ['A','B']
      then
        begin
          textbackground(0); textcolor(7);
          clrscr; gotoxy (3,10);
          writeln ('   The logged drive is now ',st[1],'.');
          writeln (' Do  you still want to use the high-');
          write   (' score table on the disk(Y/N)?');
          repeat
            ReadAKey (ch,ch1); ch:=upcase(ch);
          until ch in ['Y','N'];
          writeln (ch);
          if ch='N'
            then usefile:=false
            else
              begin
                writeln;
                writeln (' Well, please keep the disk');
                writeln (' in drive ',st[1],' while playing.');
                writeln;
                write   (' Press any key to continue...');
                ReadAKey (ch,ch1);
              end;
        end;
    if usefile then
      begin
        assign (hmkfile,scrfile);
        {$I-} reset(hmkfile);
        retcode:=IOResult;
        if retcode=0
          then begin
                 read (hmkfile,hmk[1]);
                 if IOResult<>0
                   then InitHmk
                   else
                     begin
                       secret(scrcode,1);
                       if FileSize(hmkfile)>1 then
                         begin
                           io:=IOResult; io:=DosError;
                           read (hmkfile,hmk[2]);
                           if IOResult<>0
                             then InitHmk
                             else secret (scrcode,2);
                         end;
                       io:=IOResult; io:=DosError;
                     end;
               end
          else InitHmk;
        close (hmkfile);
        i:=IOResult;
        {$I+}
      end;
  end;
begin {------------------------main-------------------------------}
  CheckBreak:=false;
  i:=detect;
  DetectGraph(i,j);
  j:=GraphResult;
  if i in [CGA,MCGA,EGA,EGA64,EGAMONO,VGA]
    then
      begin
        if i in [EGA,EGA64,EGAMONO]
          then blb:=true
          else blb:=false;
        fill:=false; norec:=false;
        readcfg;
        InitHmk;
        cover;
        GetHighScore;
        mainmenu;
      end
    else
      begin
        writeln('Can''t find CGA/EGA/VGA card.');
        writeln('MAZE 6.21 can only work in CGA/EGA/VGA mode.');
      end;
end.
