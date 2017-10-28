program New24_AnyNumbers(input,output);
uses dos;
const opr :array[1..4] of char=('+','-','*','/');
      maxnum=9;
      maxstore=1000;
type card=array[1..maxnum] of integer;
     st50=string[50];
     TimeRec=record
               hour,minute,second,frac:word;
             end;
var  k :card;
     i,j,l,t,ans,num :integer;
     op:array[0..maxnum] of char;
     intonly,same,error :boolean;
     ch:char;
     exist:set of 1..maxnum;
     Index:array[1..maxnum] of 1..maxnum;
     store:array[1..maxstore] of st50;
     point:integer;
     time1,time2:TimeRec;
{-------------------------------------------}
function calcu(expres:st50):integer;
type numbers=set of char;
var ch      :char;
    answer,i,toadd :real;
    number  :numbers;
    pointing,v :integer;
procedure readin (var toput:char);
 begin
  pointing:=succ(pointing);
  toput:=expres[pointing];
 end;
function expression  :real;
  function     term  :real;
    function factor  :real;
      begin {factor}
        if ch in number
          then begin
                 factor:=k[ord(ch)-ord('0')]; readin (ch);
               end
          else if ch='('
            then begin
                   readin (ch);
                   factor:=expression;
                   if ch<>')' then error:=true;
                   readin (ch)
                 end
            else error:=true;
      end;  {factor}
  var sign  :(multiply,divide);
      term1,fa :real;
  begin {term}
    term1:=factor;
    while (ch='*') or (ch='/') do
      begin
        if ch='*' then sign:=multiply else sign:=divide;
        readin (ch);
        if sign=multiply
           then term1:=term1*factor
           else begin
                  fa:=factor;
                  if fa=0 then error:=true
                          else
                            begin
                              term1:=term1/fa;
                              if term1>0 then toadd:=1e-6
                                         else toadd:=-1e-6;
                              if intonly and
                                 (abs(term1-trunc(term1+toadd))>1e-6)
                                then error:=true;
                            end;
                end;
      end;
    term:=term1;
  end;
var sign  :(add,minus);
    expr1 :real;
begin {expression}
  expr1:=term;
  while (ch='+') or (ch='-') do
    begin
      if ch='+' then sign:=add else sign:=minus;
      readin (ch);
      if sign=add
        then expr1:=expr1+term
        else expr1:=expr1-term
    end;
  expression:=expr1;
end;
begin {calcu}
  for v:=1 to length(expres) do
    if expres[v]='[' then expres[v]:='(';
  for v:=length(expres)+1 to 50 do expres[v]:=' ';
  pointing:=0;
  number:=['0'..'9'];
  error:=false;
  readin (ch);
  i:=expression;
  if abs(i-trunc(i+1e-6))>1e-6 then error:=true;
  if error
    then calcu:=maxint
    else begin
           if i>0 then toadd:=1e-6
                  else toadd:=-1e-6;
           calcu:=trunc(i+toadd);
         end;
end;
{-----------------------------------------------------}
procedure chk;
  var i,j,l,m:integer;
      lk :st50;
      md,am:set of char;
  function NewExpr(st:st50):boolean;
    type sorttype=array[1..20] of record
                                    st:st50;
                                    ch:char;
                                  end;
    var i,j :integer;
        min :char;
        ptr :integer;
        changed:st50;
        NewOne:boolean;
    function ChgExpr      :st50;
      function ChgTerm    :st50;
        function ChgFactor:st50;
          begin                         {---------}
            if st[ptr]<>'('             {ChgFactor}
              then                      {---------}
                begin
                  ChgFactor:=st[ptr];
                  ptr:=succ(ptr);
                end
              else
                begin
                  ptr:=succ(ptr);
                  ChgFactor:='('+ChgExpr+')';
                  ptr:=succ(ptr);
                end;
          end;
        var sort:sorttype;        {---------}
            i,j,k,start:integer;  { ChgTerm }
            s:st50;               {---------}
            ch:char;
        begin
          i:=1; start:=ptr;
          sort[1].st:=ChgFactor;
          sort[1].ch:='*';
          while st[ptr] in ['*','/'] do
            begin
              ch:=st[ptr];
              ptr:=succ(ptr);
              i:=succ(i);
              s:=ChgFactor;
              j:=pred(i);
              while (j>0) and
                    ((s<sort[j].st) or (s<=sort[j].st) and (ch='/')) do
                begin
                  sort[succ(j)]:=sort[j];
                  j:=pred(j);
                end;
              j:=succ(j);
              sort[j].st:=s; sort[j].ch:=ch;
            end;
          for j:=1 to i do
            if sort[j].ch='*' then
              begin
                s:=sort[j].st;
                k:=j;
                j:=i;
              end;
          for j:=1 to i do
            if j<>k then
              s:=s+sort[j].ch+sort[j].st;
          st:=copy(st,1,start-1)+s+copy(st,ptr,50);
          ChgTerm:=s;
        end;
      var sort:sorttype;          {---------}
          i,j,k,start:integer;    { ChgExpr }
          s:st50;                 {---------}
          ch:char;
      begin
        i:=1; start:=ptr;
        sort[1].st:=ChgTerm;
        sort[1].ch:='+';
        while st[ptr] in ['+','-'] do
          begin
            ch:=st[ptr];
            ptr:=succ(ptr);
            i:=succ(i);
            s:=ChgTerm;
            j:=pred(i);
            while (j>0) and
                  ((s<sort[j].st) or (s<=sort[j].st) and (ch='-')) do
              begin
                sort[succ(j)]:=sort[j];
                j:=pred(j);
              end;
            j:=succ(j);
            sort[j].st:=s; sort[j].ch:=ch;
          end;
        for j:=1 to i do
          if sort[j].ch='+' then
            begin
              s:=sort[j].st;
              k:=j;
              j:=i;
            end;
        for j:=1 to i do
          if j<>k then
            s:=s+sort[j].ch+sort[j].st;
        st:=copy(st,1,start-1)+s+copy(st,ptr,50);
        ChgExpr:=s;
      end;
    begin  { NewExpr }
      ptr:=1;
      for i:=1 to length(st) do
        if st[i] in ['1'..'9'] then
          begin
            min:=st[i];
            for j:=1 to length(st) do
              if st[j] in ['1'..'9'] then
                if (k[ord(st[i])-ord('0')]=k[ord(st[j])-ord('0')])
                  and (st[j]<min)
                    then min:=st[j];
            st[i]:=min;
          end;
      for i:=1 to length(st) do
        if st[i]='[' then st[i]:='(';
      for i:=length(st)+1 to 50 do
        st[i]:=' ';
      changed:=ChgExpr;
      NewOne:=true;
      for i:=1 to point do
        if store[i]=st then
          begin
            NewOne:=false;
            i:=point;
          end;
      if NewOne then begin
                       NewExpr:=true;
                       point:=succ(point);
                       store[point]:=st;
                     end
                else NewExpr:=false;
    end;
  procedure writedown(st:st50);
    var i:integer;
        same:boolean;
    procedure writeans(st:st50);
      var i:integer;
          s:st50;
      begin
        t:=succ(t);
        if t>maxstore then begin
                             writeln (^G'*** Memory Full.');
                             halt;
                           end;
        write ('No.',t:3,'  ');
        for i:=1 to length(st) do
          if (st[i]<='9') and (st[i]>'0')
            then write (k[ord(st[i])-ord('0')])
            else
              if st[i]='['
                then write ('(')
                else write (st[i]);
        writeln ('=',ans);
      end;
    procedure add(st:st50);
      var i,j,k,m:integer;
          st1,st2:st50;
          oprset:set of char;
          ch:char;
          FoundOne:boolean;
      begin
        if NewExpr(st) then
          begin
            if not intonly or (calcu(st)=ans)
              then writeans (st)
              else point:=pred(point);
          end;
        for i:=1 to pred(length(st)) do
          begin
            if st[i] in ['-','/'] then
              begin
                if st[i]='-' then oprset:=['+','-']
                             else oprset:=['*','/','+','-'];
                st1:=st; insert ('[',st1,succ(i));
                k:=0; FoundOne:=false;
                st1[length(st1)+1]:=')';
                for j:=i+2 to length(st1)+1 do
                  if st1[j]='['
                    then j:=length(st1)+1
                    else
                      begin
                        ch:=st1[j];
                        if ch='(' then k:=succ(k);
                        if ch=')' then k:=pred(k);
                        if k<=0 then
                          if (ch in oprset) or (k<0) then
                            begin
                              if (st[i]='/') and (ch in ['+','-'])
                                then k:=-1;
                              if not FoundOne
                                then
                                  begin
                                    if (st[i]='-') and (ch in ['+','-']) or
                                       (st[i]='/') and (ch in ['*','/'])
                                      then FoundOne:=true;
                                  end
                                else
                                  begin
                                    st2:=st1; insert (')',st2,j);
                                    add(st2);
                                  end;
                              case ch of
                               '+': st1[j]:='-';
                               '-': st1[j]:='+';
                               '*': st1[j]:='/';
                               '/': st1[j]:='*';
                              end;
                            end;
                        if k<0 then j:=length(st1)+1;
                      end;
              end;
          end;
      end;
    begin
      if intonly
        then
          begin
            intonly:=false;
            if calcu(st)=ans then
              begin
                intonly:=true;
                add(st);
              end;
            intonly:=true;
          end
        else
          if calcu(st)=ans then add(st);
    end;
  function stg(i:integer):char;
    begin
      stg:=chr(ord('0')+i);
    end;
  function BracketsOK(st:st50;left,right:integer):boolean;
    var kk,m,len:integer;
    begin
      BracketsOK:=false;
      len:=length(st);
      if (pred(left)>0) and (st[pred(left)] in md)
         or (succ(right)<=len) and (st[succ(right)] in md) then
        begin
          kk:=0;
          for m:=succ(left) to pred(right) do
            begin
              if st[m]='(' then kk:=succ(kk);
              if st[m]=')' then kk:=pred(kk);
              if kk=0 then
                if st[m] in am then
                  begin
                    BracketsOK:=true;
                    m:=pred(right);
                  end;
            end;
        end;
    end;
  procedure addBrackets(st:st50);
    var i,j,k1,m,mm,b1,b2,len:integer;
        ended,ok:boolean;
        st1:st50;
    begin
      len:=length(st);
      st[length(st)+1]:=')';
      for i:=1 to len-1 do
        begin
          if st[i] in am+md then
            begin
              ended:=false;
              for j:=i+1 to len+1 do
                begin
                  if st[j]='('
                    then j:=len+1
                    else
                      begin
                        if st[j]=')'
                          then ended:=true;
                        if (st[j] in am+md) or ended
                          then
                            begin
                              st1:=st;
                              insert (')',st1,j);
                              insert ('(',st1,pred(i));
                              if BracketsOK(st1,pred(i),succ(j)) then
                                begin
                                  ok:=true; b1:=0; b2:=0;
                                  for m:=i-2 downto 1 do
                                    begin
                                      if st1[m]='(' then b1:=succ(b1);
                                      if st1[m]=')' then b1:=pred(b1);
                                      if b1>0 then
                                        for mm:=j+2 to length(st1) do
                                          begin
                                            if st1[mm]='(' then
                                              b2:=succ(b2);
                                            if st1[mm]=')' then
                                              b2:=pred(b2);
                                            if b2<0 then
                                              begin
                                                if not BracketsOK(st1,m,mm)
                                                  then ok:=false;
                                                mm:=length(st1);
                                                m:=1;
                                              end;
                                          end;
                                    end;
                                  if ok then
                                    begin
                                      writedown (st1);
                                      addBrackets(st1);
                                    end;
                                end;
                            end;
                        if ended then j:=len+1;
                      end;
                end;
            end;
        end;
    end;
  begin
    md:=['*','/']; am:=['+','-'];
    lk:=stg(Index[1]);
    for i:=2 to num do
      lk:=lk+op[pred(i)]+stg(index[i]);
    writedown(lk);
    addBrackets(lk);
  end;
procedure MakeOpr(stack:integer);
  var i:integer;
  begin
    if stack<=pred(num)
      then
        for i:=1 to 4 do
          begin
            op[stack]:=opr[i];
            MakeOpr(succ(stack));
          end
      else
        chk;
  end;
procedure MakeNumbers(stack:integer);
  var i,j:integer;
      ok:boolean;
  begin
    if stack<=num
      then
        begin
          for i:=1 to num do
            if not (i in exist) then
              begin
                exist:=exist+[i];
                Index[stack]:=i;
                ok:=true;
                for j:=1 to pred(stack) do
                  if (k[Index[j]]=k[i]) and (Index[j]>=i)
                    then begin
                           ok:=false;
                           j:=pred(stack);
                         end;
                if ok then MakeNumbers(succ(stack));
                exist:=exist-[i];
              end;
        end
      else
        begin
          op[0]:=' '; op[num]:=' ';
          MakeOpr(1);
        end;
  end;

begin   {----------------------main--------------------------}
  repeat
    t:=0; point:=0;
    repeat
      write('How many numbers(1-',maxnum,')?');
      readln (num);
    until num in [1..maxnum];
    for i:=1 to num do begin
                         write ('<',i,'>: '); readln (k[i]);
                       end;
    repeat
      write ('Answer: ');
      readln (ans);
    until ans<>maxint;
    repeat
      write ('Integer only(Y/N)?');
      readln (ch); ch:=upcase(ch);
    until ch in ['Y','N'];
    if ch='Y' then intonly:=true
              else intonly:=false;
    with time1 do gettime (hour,minute,second,frac);
    {-------------------------------------------------}
    exist:=[];
    MakeNumbers(1);
    {-------------------------------------------------}
    if t=0 then writeln ('FAIL')
           else writeln ('Total=',t);
    with time2 do gettime (hour,minute,second,frac);
    for i:=1 to 30 do write ('-'); writeln;
    with time1 do
      writeln ('Started  at ',hour,':',minute,':',second,'.',frac);
    with time2 do
      writeln ('Finished at ',hour,':',minute,':',second,'.',frac);
    for i:=1 to 30 do write ('-'); writeln;
    repeat
      write ('Again(Y/N)?');
      readln (ch); ch:=upcase(ch);
    until ch in ['Y','N'];
  until ch='N';
end.
