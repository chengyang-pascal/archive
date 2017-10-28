program Calculate_24; { use tree }
{$M 65520,0,655360}
{$V-}
uses dos;
const max=8;
      maxmodes=500;
      chars:array[1..4] of char=('+','-','*','/');
type tree=^treenode;
     treenode=record
                l,r:tree;
              end;
     realtree=^realtreenode;
     realtreenode=record
                    l,r:realtree;
                    case integer of
                    0: (opr:char);
                    1: (number:integer);
                  end;
     store=^storenode;
     storenode=record
                 mode:string[70];
                 l,r:store;
               end;
var n,ans,total:integer;
    a,b:array[1..max] of integer;
    mode:array[1..max,1..maxmodes] of tree;
    num:array[0..max] of integer;
    expr:realtree;
    root:store;
    marked:pointer;
    ch:char;
    hh,mm,ss,ff,hhh,mmm,sss,fff:word;
procedure inputdata;
  var i,j:integer;
  begin
    repeat
      write('How many numbers(1-',max,')?');
      readln(n);
    until (n>0) and (n<=max);
    for i:=1 to n do
      begin
        write('<',i,'>:');
        readln(a[i]);
        b[i]:=i;
        for j:=1 to pred(i) do
          if a[i]=a[j] then
            begin
              b[i]:=j; j:=pred(i);
            end;
      end;
    repeat
      write('Answer:');
      readln(ans);
      if ans=maxint then
        writeln('The answer must be less than ',maxint,'.');
    until ans<>maxint;
    gettime(hh,mm,ss,ff);
  end;
procedure maketree;
  var i,j,k,x,y:integer;
      p:tree;
  begin
    new(p);
    p^.l:=nil; p^.r:=nil;
    mode[1,1]:=p;
    num[0]:=1; num[1]:=1;
    for i:=2 to pred(n) do
      begin
        num[i]:=0;
        for j:=0 to pred(i) do
          begin
            k:=pred(i)-j;
            for x:=1 to num[j] do
              for y:=1 to num[k] do
                begin
                  new(p);
                  if j=0 then p^.l:=nil
                         else p^.l:=mode[j,x];
                  if k=0 then p^.r:=nil
                         else p^.r:=mode[k,y];
                  inc(num[i]);
                  mode[i,num[i]]:=p;
                end;
          end;
      end;
  end;
procedure search;
  type op=array[1..max] of realtree;
  var i,j,k,m,c1,c2:integer;
      oprs,numbers:op;
      exist:set of 1..max;
      ok:boolean;
  procedure calculate;
    var i,j:integer;
        s:string;
    function result(expr:realtree):integer;
      var temp1,temp2:integer;
      begin
        if (expr^.l=nil) and (expr^.r=nil)
          then
            result:=a[expr^.number]
          else
            begin
              temp1:=result(expr^.l);
              temp2:=result(expr^.r);
              if (temp1=maxint) or (temp2=maxint)
                then result:=maxint
                else
                  case expr^.opr of
                   '+': result:=temp1+temp2;
                   '-': result:=temp1-temp2;
                   '*': result:=temp1*temp2;
                   '/': if temp2=0
                          then result:=maxint
                          else
                            if temp1 mod temp2<>0
                              then result:=maxint
                              else result:=temp1 div temp2;
                  end;
            end;
      end;
    function change(expr:realtree):string;
      var temp1,temp2:string;
          s:string;
      begin
        if (expr^.l=nil) and (expr^.r=nil)
          then
            change:=chr(48+expr^.number)
          else
            begin
              temp1:=change(expr^.l); temp2:=change(expr^.r);
              if (expr^.l^.l=nil) and (expr^.l^.r=nil)
                then
                  s:=temp1
                else
                  if (expr^.opr in ['*','/'])
                     and (expr^.l^.opr in ['+','-'])
                    then s:='('+temp1+')'
                    else s:=temp1;
              s:=s+expr^.opr;
              if (expr^.r^.l=nil) and (expr^.r^.r=nil)
                then
                  s:=s+temp2
                else
                  if ((expr^.opr in ['*','/'])
                     and (expr^.r^.opr in ['+','-']))
                     or
                     ((expr^.opr='-') and (expr^.r^.opr in ['+','-']))
                     or
                     (expr^.opr='/')
                    then s:=s+'('+temp2+')'
                    else s:=s+temp2;
              change:=s;
            end;
      end;
    function smallest(s:string):string;
      var ptr:integer;
      function expression:string;
        function term:string;
          function factor:string;
            var temp:string;
            begin { factor }
              if s[ptr]='('
                then
                  begin
                    inc(ptr);
                    temp:=expression;
                    factor:='('+temp+')';
                  end
                else
                  factor:=s[ptr];
              inc(ptr);
            end;
          type tempmode=record
                          mode:string[70];
                          opr:char;
                        end;
          var temp:array[1..max] of tempmode;
              temp1:tempmode;
              i,j:integer;
              changed:boolean;
              t:string[70];
          begin  { term }
            with temp[1] do
              begin
                mode:=factor; opr:='*';
              end;
            i:=1;
            while s[ptr] in ['*','/'] do
              begin
                inc(i);
                temp1.opr:=s[ptr];
                inc(ptr);
                temp1.mode:=factor;
                changed:=false;
                for j:=pred(i) downto 1 do
                  begin
                    if (temp1.mode>temp[j].mode) or
                       ((temp1.mode=temp[j].mode) and (temp1.opr='/'))
                      then begin
                             temp[succ(j)]:=temp1; changed:=true;
                             j:=1;
                           end
                      else temp[succ(j)]:=temp[j];
                  end;
                if not changed then
                  temp[1]:=temp1;
              end;
            t:='';
            for j:=1 to i do
              t:=t+temp[j].opr+temp[j].mode;
            term:=t;
          end;
        type tempmode=record
                        mode:string[70];
                        opr:char;
                      end;
        var temp:array[1..max] of tempmode;
            temp1:tempmode;
            i,j:integer;
            changed:boolean;
            t:string[70];
        begin  { expression }
          with temp[1] do
            begin
              mode:=term; opr:='+';
            end;
          i:=1;
          while s[ptr] in ['+','-'] do
            begin
              inc(i);
              temp1.opr:=s[ptr];
              inc(ptr);
              temp1.mode:=term;
              changed:=false;
              for j:=pred(i) downto 1 do
                begin
                  if (temp1.mode>temp[j].mode) or
                     ((temp1.mode=temp[j].mode) and (temp1.opr='-'))
                    then begin
                           temp[succ(j)]:=temp1; changed:=true;
                           j:=1;
                         end
                    else temp[succ(j)]:=temp[j];
                end;
              if not changed then
                temp[1]:=temp1;
            end;
          t:='';
          for j:=1 to i do
            t:=t+temp[j].opr+temp[j].mode;
          expression:=t;
        end;
      begin  { smallest }
        ptr:=1;
        s[succ(length(s))]:=';';
        smallest:=expression;
      end;
    function ModeExist(s:string):boolean;
      var p,old:store;
      begin
        p:=root;
        repeat
          old:=p;
          if s>p^.mode
            then p:=p^.r
            else
              if s<p^.mode
                then p:=p^.l;
        until (p=nil) or (s=p^.mode);
        if p=nil
          then
            begin
              new(p);
              if s>old^.mode then old^.r:=p
                             else old^.l:=p;
              with p^ do
                begin
                  mode:=s; l:=nil; r:=nil;
                end;
              ModeExist:=false;
            end
          else
            ModeExist:=true;
      end;
    procedure print(s:string);
      var i:integer;
          s1:string;
      begin
        for i:=1 to length(s) do
          if s[i] in ['0'..'9'] then
            s[i]:=chr(48+b[ord(s[i])-48]);
        s1:=smallest(s);
        if not ModeExist(s1) then
          begin
            inc(total);
            write('[',total,'] ');
            for i:=1 to length(s) do
              if s[i] in ['0'..'9']
                then write(a[ord(s[i])-48])
                else write(s[i]);
            writeln('=',ans);
          end;
      end;
    begin
      i:=result(expr);
      if i=ans then
        begin
          s:=change(expr);
          print(s);
        end;
    end;
  procedure makeopr(s:integer);
    var i,j:integer;
    begin
      if s>pred(n)
        then
          calculate
        else
          begin
            for i:=1 to 4 do
              if (i in [2,4]) or (oprs[s]^.l<>nil) then
                begin
                  oprs[s]^.opr:=chars[i];
                  makeopr(succ(s));
                end;
          end;
    end;
  procedure makenumber(s:integer);
    var i,j:integer;
    begin
      if s>n
        then
          makeopr(1)
        else
          begin
            for i:=1 to n do
              if not (i in exist) then
                begin
                  ok:=true;
                  for j:=1 to pred(s) do
                    begin
                      m:=numbers[j]^.number;
                      if (b[m]=b[i]) and (i<m) then
                        begin
                          ok:=false; j:=pred(s);
                        end;
                    end;
                  if ok then
                    begin
                      numbers[s]^.number:=i;
                      exist:=exist+[i];
                      makenumber(succ(s));
                      exist:=exist-[i];
                    end;
                end;
          end;
    end;
  procedure copytree(src:tree;var dest:realtree);
    var p,q:realtree;
    begin
      new(p);
      dest:=p;
      inc(c1);
      oprs[c1]:=p;
      if src^.l=nil
        then
          begin
            new(q); p^.l:=q;
            q^.l:=nil; q^.r:=nil;
            inc(c2); numbers[c2]:=q;
          end
        else
          copytree(src^.l,p^.l);
      if src^.r=nil
        then
          begin
            new(q); p^.r:=q;
            q^.l:=nil; q^.r:=nil;
            inc(c2); numbers[c2]:=q;
          end
        else
          copytree(src^.r,p^.r);
    end;
  begin
    new(root);
    with root^ do
      begin
        mode:=''; l:=nil; r:=nil;
      end;
    k:=pred(n);
    for i:=1 to num[k] do
      begin
        c1:=0; c2:=0;
        copytree(mode[k,i],expr);
        exist:=[];
        makenumber(1);
      end;
  end;
begin
  repeat
    mark(marked);
    inputdata;
    total:=0;
    if n=1
      then
        begin
          if a[1]<>ans
            then total:=0
            else
              begin
                writeln('[1] ',ans,'=',ans);
                total:=1;
              end;
        end
      else
        begin
          maketree;
          search;
        end;
    if total=0 then writeln('FAIL')
               else writeln('Total=',total);
    gettime(hhh,mmm,sss,fff);
    writeln('---------------------------------');
    writeln('Started at  ',hh,':',mm,':',ss,'.',ff);
    writeln('Finished at ',hhh,':',mmm,':',sss,'.',fff);
    writeln('---------------------------------');
    release(marked);
    repeat
      write('Again(Y/N)?');
      readln(ch);
      ch:=upcase(ch);
    until ch in ['Y','N'];
  until ch='N';
end.
