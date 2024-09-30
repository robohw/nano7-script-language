program nano7; // 24.09.25 v1.2 FIN - KeyWords: INP, IF, JMP, RET, PRN, TRC, NOP  
{$MODE FPC}    // RET implanted, GetVal speedUp, Arr.limit = 32767, project closed. 
 
 uses SysUtils;      
 type                            // Proto, for LABELs. 
   TLabel = record
     Name: string;               // name, and 
     Addr: Word;                 // address (linenum)
   end;
   
 const
 ArMAX  = 32767;                 // upper limit of builtin array (Ar)
 CNTMAX = 2000000;               // avoid infinitive loops

 var {global}
   Code   : array of string;     // TEMP of the runnable nano7 code. Max. 65535 lines
   tokens : array of string;     // TEMP of the actual line content, in tokenised form
   Labels : array of TLabel;     // list of labels
   Vars : array['B'..'Z'] of LongInt;
   Ar     : array of LongInt;    // builtin longint array with 64k capacity
   LineNum: Word = 0;            // program counter 
   Stack  : Word = 0;            // pseudo stack (for RET(urn))
   Trace  : Boolean = False;
   Counter: LongInt = 0;
   InFile,OutFile : text;
 
 procedure Error(const Msg: string);
 begin
   Writeln(OutFile,'ERROR (line ', LineNum, '): ', Msg);
   Writeln(OutFile,'Code: ', Code[LineNum-1]);
   close(OutFile);
   Halt(1);
 end;

 procedure Split(inStr: string);
 var
   i, Index: byte;
 begin
 Index := 0;
 SetLength(Tokens, 1);
 Tokens[0] := ''; 
  
 for I := 1 to Length(inStr) do  
   begin    
    if inStr[I] <> ' ' then
      begin
        if (I = 1) or (inStr[I - 1] = ' ') then
          begin
            Inc(Index);
            SetLength(Tokens, Index);
          end;
        Tokens[Index - 1] := Tokens[Index - 1] + inStr[I];
      end;
   end;
 end;
 
 procedure SetLabelAddr(const Name: string; Addr: Word);
 var
   i: Integer;
 begin
   for i := 2 to length(name) do
     if not (name[i] in ['A'..'Z','_']) then error('illegal char in LABEL '+name);   
   for i := 0 to High(Labels) do
     if Labels[i].Name = Name then Error('Label "' + Name + '" already exists.');
   SetLength(Labels, Length(Labels) + 1);
   Labels[High(Labels)].Name := Name;
   Labels[High(Labels)].Addr := Addr;
 end;
 
 function GetLabelAddr(const Name: string): Word;
 var
   i: Integer;
 begin
   if(Name[1] <> '.') then Error('missing dot (label)');
   GetLabelAddr := 0;  
   for i := 0 to High(Labels) do if Labels[i].Name = Name then Exit(Labels[i].Addr);
   Error('Label not found: ' + Name);
 end;

 function ExtractIndex(s: string): word;  // for PRN instruction
 var
  i: Word;
 begin
  s := Copy(s, 3, Length(s) - 2);  
  if (Length(s) = 1) and (s[1] in ['B'..'Z']) then i := Vars[s[1]] else i := StrToIntDef(s, -1);  
  if (i < 0) or (i > ArMax) then Error('too small/big (or A) index: ' + s);
  ExtractIndex := i;
 end;

 function GetIndex(s: string): word;
 var
   i: Word;
 begin
   i := ExtractIndex(s);
   if (i >= Length(Ar)) then SetLength(Ar, i + 1); 
   GetIndex := i;
 end;

 function GetVal(n: Byte): LongInt;
 var
   i: LongInt;
 begin   
   if (tokens[n][1]in['B'..'Z'])and (Length(tokens[n])>1)then Error('Invalid ID: '+tokens[n]);
   if (tokens[n][1] in ['-','0'..'9']) then
       if not TryStrToInt(tokens[n],i) then Error('Invalid numeric value ' + tokens[n]);  
   if (tokens[n][1] = 'A') and ((Length(tokens[n])< 3) or (tokens[n][2] <> '.')) then
       Error('invalid A.index: '+tokens[n]);
 
   case tokens[n][1] of
     'B'..'Q', 'S'..'Z': Exit(Vars[tokens[n][1]]);
     'A': Exit(Ar[GetIndex(tokens[n])]);  
     'R': Exit(Random(Vars['R']));
     else i := StrToIntDef(tokens[n], Low(LongInt));
     if i = Low(LongInt) then Error('Invalid value: ' + tokens[n]);
     GetVal := i;
   end; // case
 end;
 
 function Calculate(op1, op2: Integer; oper: Char): Integer;
 begin
   case oper of
     '+': Calculate := op1 + op2;
     '-': Calculate := op1 - op2;
     '*': Calculate := op1 * op2;
     '/': if (op1=0) or (op2=0) then Error('Div by 0') else Calculate := op1 div op2;
     '%': if (op1=0) or (op2=0) then Error('Mod by 0') else Calculate := op1 mod op2;
   else
     Error('Invalid operator: ' + oper);  
   end;
 end; 

 function Input(n: byte): longint;
 var
 inStr: string;
 begin
   repeat
     write(tokens[n],': ');
     inStr:= '';
     readln(inStr);    
   until Trystrtoint(inStr,Input);
 end;
 
 procedure SetVal(n: Byte);
 var
  value: LongInt;
  i: Integer;
 begin
  if not (tokens[n][1]   in ['A'..'Z'])    then Error('Invalid var ID: ' + tokens[n]);
  if not (tokens[n+1][1] in ['=','+','-']) then Error('syntax error: ' + tokens[n+1]);
  if (tokens[n+1] = '=') and (length(tokens) < 3) then error('missing value/var ID');  
 
  if tokens[n+2] = 'INP'    then Value := Input(n)  
  else if tokens[n+1] = '+' then value := GetVal(n) + 1
  else if tokens[n+1] = '-' then value := GetVal(n) - 1
  else
  begin
    case Length(tokens) of
      3, 7: value := GetVal(n + 2);
      5, 9: value := Calculate(GetVal(n + 2), GetVal(n + 4), tokens[n + 3][1]);
    else
      Error('Invalid (LET) syntax');
    end;  // case
  end;

  if tokens[n][1] = 'A' then
  begin
    i := GetIndex(tokens[n]);
    Ar[i] := value;
  end
  else Vars[tokens[n][1]] := value;
 end;
 
 procedure Printer(n: byte);
 var i: longInt;  
 begin
 for i := n to High(tokens) do
     if tokens[i][1] = 'A' then Write(OutFile,Ar[ExtractIndex(tokens[i])])  
     else
     if tokens[i][1] in ['B'..'R'] then Write(OutFile,Vars[tokens[i][1]])
     else Write(OutFile,Chr(Vars[tokens[i][1]]));
 end;
 
 procedure ExecuteMe;
 begin
   LineNum := 1;
   while (LineNum <= High(Code)) do
   begin
     Split(Code[LineNum]);
     Inc(LineNum);
     case tokens[0] of
       'IF':begin
             if (length(tokens[2])>1) or not (tokens[2][1] in ['<','>','=']) 
                then Error('unknown LogOp: '+tokens[2]);
             if ((tokens[2][1]='<') and (GetVal(1) < GetVal(3))) or                
                ((tokens[2][1]='>') and (GetVal(1) > GetVal(3))) or
                ((tokens[2][1]='=') and (GetVal(1) = GetVal(3))) then
              begin
                case tokens[4] of
                  'JMP': begin
                           Stack   := linenum;   
                           LineNum := GetLabelAddr(tokens[5]);
                         end;
                  'PRN': Printer(5);
                  'RET': if Stack = 0 then Error('No return(R)') else LineNum := Stack;
                  else SetVal(4);
                end; // case
              end; // if
            end; // 'IF:'
       'JMP': begin
                Stack   := linenum;   
                LineNum := GetLabelAddr(tokens[1]);
              end;
       'RET': if Stack = 0 then Error('No return address found') else LineNum := Stack;
       'NOP': ; // No operation
       'PRN': Printer(1);
     else SetVal(0);
     end;
     if Counter > CNTMAX then Error('infinite loop detected') else Inc(Counter);
   end;
 end;
 
 function CharCheck(const l: string): Byte;
 var i: byte;
 begin
   for i := 1 to Length(l) do
     if not(l[i]in['0'..'9','A'..'Z','<','>','=','+','-','*','/','%','.',' ','_']) then Exit(i);
   CharCheck := 0;
 end;

 procedure LoadProgram;
 var
   i: byte;
   Line: string;
 begin
   for i:= Ord('B') to Ord('Z') do vars[Chr(i)]:= -2147483648;
   Randomize;
   Vars['R'] := 100; // Range for random numbers: 0..99
   Vars['S'] := 32;  // ascii space preset (for print)
   Vars['T'] := 10;  // ascii newline preset (for print)
   
   SetLength(Code, 1);
   SetLength(Labels, 0);
   SetLength(Ar, 1);
   LineNum := 0;
   while not Eof(InFile) do
   begin
     ReadLn(InFile,Line);
     Line := UpperCase(Trim(Copy(Line, 1, Pos(';', Line + ';') - 1))); // Comment filter
     if Line = ''     then Continue;    
     if Line = 'TRC'  then Trace := True else
     if Line[1] = '.' then SetLabelAddr(Line, LineNum + 1)
     else
     begin
       if CharCheck(Line) > 0 then Error('Illegal character in line: ' + Line);
       Inc(LineNum);
       SetLength(Code, LineNum + 1);
       Code[LineNum] := Line;
     end;
   end;
   close(InFile);
 end;
 
 procedure PrintState;
 var
   i: Integer;
 begin
   Writeln(OutFile);
   Writeln(OutFile,'-------------- (', Counter, ' lines done) - Code:');
   for i := 1 to length(Code)-1 do
     if i < 10 then Writeln(OutFile,' ',i,'  ', Code[i]) else Writeln(OutFile,i,'  ', Code[i]);
   if Length(Labels) > 0 then
   begin
     Writeln(OutFile);
     Writeln(OutFile,'-------------- Label(s):');
     for i := 0 to length(Labels)-1 do Writeln(OutFile,Labels[i].Name, #9, Labels[i].Addr);
   end;  
   Writeln(OutFile);
   Writeln(OutFile,'-------------- Vars (B..Z):');
   for i := Ord('B') to Ord('Z') do
       if Vars[Chr(i)] > -2147483648 then Writeln(OutFile,Chr(i), ' ', Vars[Chr(i)]);  
   Writeln(OutFile,'-------------- Array element(s):');
   for i := 0 to length(Ar)-1 do Writeln(OutFile,'A.', i, ' = ', Ar[i]);
 end;
 
 begin // ------------------------- main
   if paramstr(1) <> '' then
   begin
    assign(InFile,paramstr(1));
    reset(InFile);
    assign(OutFile,paramstr(1)+'.out');
    rewrite(OutFile);  
   end
   else 
    begin
    writeln(' no input file. Try: nano7.exe your_script');
    halt(1); 
    end;
    
   LoadProgram;  
   ExecuteMe;
   if Trace then PrintState;
   close(OutFile)
 end.

