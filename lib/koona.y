class Koona::Parser
  token TIDENTIFIER TDOUBLE TINTEGER TSTRING TCALL
  token TCEQ TCNE TCLT TCLE TCGT TCGE TEQUAL
  token TLPAREN TRPAREN TLBRACE TRBRACE TCOMMA TDOT
  token TPLUS TMINUS TMUL TDIV
  token TRETURN TREQUIRE TIF TELSE
  token TTRUE TFALSE

  start program
  rule
  program : stmts {result = Koona::AST::NBlock.new(Koona::AST::NStatementList.new); result.statementlist.statements << val[0]}
  stmts : stmt {result = Koona::AST::NStatementList.new; result.statements << val[0]}
        | stmts stmt {val[0].statements << val[1]}

  stmt : return_stmt
       | expr
       | block
       | func_decl
       | var_decl
       | var_assign
       | if_stmt
       | require_stmt

  block : TLBRACE TRBRACE {result = Koona::AST::NBlock.new}
        | TLBRACE stmts TRBRACE {result = Koona::AST::NBlock.new(Koona::AST::NStatementList.new); result.statementlist.statements << val[1]}

  var_decl : ident ident TEQUAL expr {result = Koona::AST::NVariableDeclaration.new(val[0], val[1], val[3], val[2])}

  var_assign : ident TEQUAL expr {result = Koona::AST::NVariableAssignment.new(val[0], val[2], val[1])}

  if_stmt : TIF TLPAREN expr TRPAREN block {result = Koona::AST::NIf.new(val[2], val[4], val[0])}

  func_decl : ident ident TLPAREN func_decl_args TRPAREN block
            {result = Koona::AST::NFunctionDeclaration.new(val[0], val[1], val[3], val[5], val[2])}

  func_decl_args : {result = Koona::AST::VariableList.new}
                 | ident ident {result = Koona::AST::VariableList.new; result.variables << Koona::AST::FunctionVar.new(val[0], val[1])}
                 | func_decl_args TCOMMA ident ident {val[0].variables << Koona::AST::FunctionVar.new(val[2], val[3])}

  require_stmt : TREQUIRE string {result = Koona::AST::NRequire.new(val[1], val[0])}

  return_stmt : TRETURN {result = Koona::AST::NReturn.new(nil, val[0])}
              | TRETURN expr {result = Koona::AST::NReturn.new(val[1], val[0])}

  ident : TIDENTIFIER {result = Koona::AST::NIdentifier.new(val[0])}

  numeric : TINTEGER {result = Koona::AST::NInteger.new(val[0])}
          | TDOUBLE {result = Koona::AST::NFloat.new(val[0])}

  string : TSTRING {result = Koona::AST::NString.new(val[0])}

  bool : TTRUE {result = Koona::AST::NBool.new(val[0])}
       | TFALSE {result = Koona::AST::NBool.new(val[0])}

  expr : numeric
       | string
       | bool
       | ident
       | func_call
       | expr binop expr {result = Koona::AST::NBinaryOperator.new(val[0], val[1], val[2])}
       | TLPAREN expr TRPAREN {result = val[1]}

  func_call : ident TLPAREN call_args TRPAREN {result = Koona::AST::NFunctionCall.new(val[0], val[2])}
            | TCALL ident TLPAREN call_args TRPAREN {result = Koona::AST::NCFunctionCall.new(val[1], val[3])}

  call_args : {result = Koona::AST::VariableList.new}
            | expr {result = Koona::AST::VariableList.new; result.variables << val[0]}
            | call_args TCOMMA expr {val[0].variables << val[2]}

  binop : TCEQ | TCNE | TCLT | TCLE | TCGT | TCGE
             | TPLUS | TMINUS | TMUL | TDIV
end

---- header
  require_relative './lexer'
  require_relative './ast'


---- inner
  def on_error(tok, val, vstack)
    $stderr.puts "#{val.filename}:#{val.lineno} Parse error on value: \"#{val.value}\"", "Stack: #{vstack.inspect}"
  end
  def parse(tokens)
    @tokens = tokens
    do_parse
  end

  def next_token
    @tokens.shift
  end
