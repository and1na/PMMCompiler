grammar Pmm;
@header{
    import ast.expression.*;
    import ast.node.*;
    import ast.type.*;
    import ast.type.struct.*;
    import ast.definition.*;
    import ast.statement.*;
    import ast.*;
    import errorhandler.*;

}

program returns [Program ast]
    locals [List<FunctionDefinition> funcDefinitions = new ArrayList<FunctionDefinition>(),
            List<VarDefinition> globalVarDefs = new ArrayList<VarDefinition>()]:
                        (v=varDefinition {$globalVarDefs.addAll($v.ast);} | f=funcDefinition {$funcDefinitions.add($f.ast);})*
                        main EOF
                        {
                            $funcDefinitions.add($main.ast);
                            $ast = new Program(0,0,$globalVarDefs,$funcDefinitions);
                        }
                ;

main returns [FunctionDefinition ast]
    locals [List<VarDefinition> bodyVarDefs = new ArrayList<VarDefinition>(),
        List<Statement> statements = new ArrayList<Statement>()]:
            kw='def' mn='main' '(' ')' dots=':' '{' (vd=varDefinition {$bodyVarDefs.addAll($vd.ast);})*  (st=statement {$statements.addAll($st.ast);} )* '}'

            {
                $ast = new FunctionDefinition($kw.getLine(),$kw.getCharPositionInLine() + 1,
                                              $mn.text,
                                              new Function($dots.getLine(),
                                                               $dots.getCharPositionInLine() + 1,
                                                               new VoidType(0,0) ,
                                                               new ArrayList<VarDefinition>()),
                                              $bodyVarDefs,
                                              $statements);
            }
            ;



expression returns [Expression ast]:  INT_CONSTANT {$ast = new IntLiteral($INT_CONSTANT.getLine(), $INT_CONSTANT.getCharPositionInLine() + 1, LexerHelper.lexemeToInt($INT_CONSTANT.text));}
            | REAL_CONSTANT
              {$ast = new FloatLiteral($REAL_CONSTANT.getLine(), $REAL_CONSTANT.getCharPositionInLine() + 1, LexerHelper.lexemeToReal($REAL_CONSTANT.text));}
            | CHAR_CONSTANT
              {$ast = new CharLiteral($CHAR_CONSTANT.getLine(), $CHAR_CONSTANT.getCharPositionInLine() + 1, LexerHelper.lexemeToChar($CHAR_CONSTANT.text));}
            | ID
              {$ast = new Variable($ID.getLine(),$ID.getCharPositionInLine()+1,$ID.text);}
            | functioninvocation
              {$ast = $functioninvocation.ast;}
            | '(' e=expression ')'
                {$ast = $e.ast;}
            | e1=expression pos='[' e2=expression ']'
              {$ast = new ArrayAccess($pos.getLine(),$pos.getCharPositionInLine()+1,$e1.ast,$e2.ast);}/**ARRAY ACCESS**/
            | e=expression '.' ID /*Struct access*/
              {$ast = new StructAccess($ID.getLine(),$ID.getCharPositionInLine()+1,$ID.text,$e.ast);}
            | pos='(' t=type ')' exp=expression
              {$ast=new Cast($pos.getLine(),$pos.getCharPositionInLine()+1,$type.ast, $exp.ast);}
            | minus='-' exp=expression
              {$ast = new UnaryMinus($minus.getLine(),$minus.getCharPositionInLine()+1, $exp.ast);}
            | negation='!' exp=expression
              {$ast = new Negation($negation.getLine(),$negation.getCharPositionInLine()+1, $exp.ast);}
            | exp1=expression operator=('*'|'/'|'%') exp2=expression
              {$ast = new Arithmetic($operator.getLine(),$operator.getCharPositionInLine()+1,$exp1.ast,$exp2.ast,$operator.text);}
            | exp1=expression operator=('+'|'-') exp2=expression
              {$ast = new Arithmetic($operator.getLine(),$operator.getCharPositionInLine()+1,$exp1.ast,$exp2.ast,$operator.text);}
            | exp1=expression operator=('>'|'>='|'<'|'<='|'!='|'==') exp2=expression
              {$ast = new ArithmeticComparison($operator.getLine(),$operator.getCharPositionInLine()+1,$exp1.ast,$exp2.ast,$operator.text);}
            | exp1=expression operator=('&&'|'||') exp2=expression
              {$ast = new Logical($operator.getLine(),$operator.getCharPositionInLine()+1,$exp1.ast,$exp2.ast,$operator.text);}
            ;

statement returns [List<Statement> ast = new ArrayList<Statement>()]
    locals [List<Statement> elseBodyL = new ArrayList<Statement>(),
            boolean hasElseBody = false]:
            ret='return' expression ';'
                {$ast.add(new Return($ret.getLine(),$ret.getCharPositionInLine()+1,$expression.ast));}
          | kw='print' expressionList ';'
                {
                    for (Expression expression : $expressionList.ast) {
                        $ast.add(new Print($kw.getLine(), $kw.getCharPositionInLine()+1, expression));
                    }
                }
          | kw='input' expressionList ';'
               {
                    for (Expression expression : $expressionList.ast) {
                        $ast.add(new Input($kw.getLine(), $kw.getCharPositionInLine()+1, expression));
                    }
               }
          | var=expression eq='=' val=expression ';'
               {$ast.add(new Assignment($eq.getLine(),$eq.getCharPositionInLine()+1,$var.ast,$val.ast));}
          | kw='while' cond=expression ':' bd=body
                {$ast.add(new While($kw.getLine(), $kw.getCharPositionInLine()+1, $body.ast, $cond.ast));}
          | kw='if' cond=expression ':' ifbody=body ('else' ':' elsebody=body {
                                                                                $elseBodyL.addAll($elsebody.ast);
                                                                                }
                                                    )?
                {
                    $ast.add(new If_Else($kw.getLine(), $kw.getCharPositionInLine()+1,$ifbody.ast,
                        $elseBodyL,$cond.ast));
                }
          | funcInv=functioninvocation ';'
                {$ast.add($funcInv.ast);}
          ;


body returns [List<Statement> ast = new ArrayList<Statement>()]:
    st=statement { $ast.addAll($st.ast); } | '{' (st2=statement { $ast.addAll($st2.ast);} )*  '}' ;




expressionList returns [List<Expression> ast = new ArrayList<Expression>()]:
            (e1=expression {$ast.add($e1.ast);} (',' e2=expression {$ast.add($e2.ast);})* )?;

functioninvocation returns [FunctionInvocation ast]:
            /**function variable*/ ID '(' exps=expressionList ')'
            {$ast = new FunctionInvocation($ID.getLine(),$ID.getCharPositionInLine() + 1,
                $exps.ast,new Variable($ID.getLine(),$ID.getCharPositionInLine(),$ID.text));};



funcDefinition returns [FunctionDefinition ast] locals [List<VarDefinition> bodyVarDefs =
                                                            new ArrayList<VarDefinition>(),
                                                            List<Statement> statements = new ArrayList<Statement>(),
                                                            Type returnType = null
                                                            ]:
        kw='def' ID'(' parametersList ')' dots=':' (rt=basicType {$returnType=$rt.ast;})? '{' (vd=varDefinition {$bodyVarDefs.addAll($vd.ast);})* (st=statement {$statements.addAll($st.ast);})* '}'
            {

            if($returnType==null){
                $returnType=new VoidType(0,0);
            }
            $ast = new FunctionDefinition($kw.getLine(),$kw.getCharPositionInLine() + 1,$ID.text,
                new Function($dots.getLine(),$dots.getCharPositionInLine() + 1,$returnType, $parametersList.ast),
                   $bodyVarDefs, $statements);
            }
            ;

parametersList returns [List<VarDefinition> ast = new ArrayList<VarDefinition>()]:
            (id1=parameter {$ast.add($id1.ast);} (',' id2=parameter {$ast.add($id2.ast);})* )?;

type returns [Type ast]:
        basicType
        {$ast=$basicType.ast;}
      | bracket='[' INT_CONSTANT ']' type
        {$ast=new Array($bracket.getLine(),$bracket.getCharPositionInLine()+1,LexerHelper.lexemeToInt($INT_CONSTANT.text),$type.ast);}
      | st='struct' '{'   structFields  '}'
        {$ast = new Struct($st.getLine(),$st.getCharPositionInLine() + 1,$structFields.ast);}
      ;

structFields returns [List<StructField> ast = new ArrayList<StructField>()]: (idList=ids dots=':' tp=type  ';'
                    {
                        for (Variable v : $idList.ast) {

                            StructField newPossibleField =
                                new StructField(v.getLine(), v.getColumn(), $tp.ast, v.getName());
                            if($ast.contains(newPossibleField)){
                                new ErrorType(v.getLine(),v.getColumn(),"StructField " + "\'" + v.getName() +  "\'" +   " already defined");
                            }else{
                                $ast.add(newPossibleField);
                            }
                        }
                     }
                    )*
                    ;


ids returns [List<Variable> ast = new ArrayList<Variable>()]:
            id1=ID { $ast.add(new Variable($id1.getLine(), $id1.getCharPositionInLine() + 1, $id1.text)); }
                (','id2=ID { $ast.add(new Variable($id2.getLine(), $id2.getCharPositionInLine() + 1, $id2.text)); })*
            ;

basicType returns [Type ast]:
              int='int'
              {$ast=new IntType($int.getLine(),$int.getCharPositionInLine()+1);}
            | double='double'
              {$ast=new DoubleType($double.getLine(),$double.getCharPositionInLine()+1);}
            | char='char'
              {$ast=new CharType($char.getLine(),$char.getCharPositionInLine()+1);}
            | /*void**/
            ;

varDefinition returns [List<VarDefinition> ast = new ArrayList<VarDefinition>()]:
                idl=ids  ':' t=type  ';'
                {
                    for(Variable var: $idl.ast){
                        VarDefinition newPossibleVarDef = new VarDefinition(var.getLine(), var.getColumn(),var.getName(),$t.ast);
                        if($ast.contains(newPossibleVarDef)){
                                new ErrorType(var.getLine(),var.getColumn(),"Variable " + "\'" + var.getName() + "\'" + " already defined");
                        }else{
                            $ast.add(newPossibleVarDef);
                        }
                    }
                }
                ;

parameter returns [VarDefinition ast]: id=ID ':' type
                    {$ast = new VarDefinition($id.getLine(),$id.getCharPositionInLine()+1,$id.text,$type.ast);};


/*LEXER PATTERNS*/

INT_CONSTANT: ([1-9][0-9]* | '0');

REAL_CONSTANT: (DOTTED_REAL|EXPONENT_REAL);

CHAR_CONSTANT:  (EXPLICIT_CHAR|NUMERIC_CHAR|SPECIAL_CHAR);

ID: ('_'|LETRA)(LETRA|INT_CONSTANT|'_')*;

ONE_LINE_COMMENT: '#'.*?('\n'|EOF) -> skip;

MULTI_LINE_COMMENT: '"''"''"'.*?'"''"''"' -> skip;

SPACE: ' ' -> skip;

TRASH:  ('\n'|'\r'|'\t') -> skip;


/**FRAGMENTS**/
fragment
EXPLICIT_CHAR: '\''.'\'';

fragment
NUMERIC_CHAR: '\'\\' INT_CONSTANT '\'';

fragment
SPECIAL_CHAR: '\'\\'('n'|'t')'\'';

fragment
LETRA:  [a-zA-Z];

fragment
DOTTED_REAL: ( (([1-9][0-9]*|'0')?'.'[0-9]+) /**Digits after point and digits at both sides**/
             | (([1-9][0-9]*|'0')+'.')/**Digits before point**/
             );

fragment
EXPONENT_REAL: (DOTTED_REAL|INT_CONSTANT)('e'|'E')('+'|'-')?INT_CONSTANT;








