package ast.definition;

import ast.node.AbstractASTNode;
import ast.statement.Statement;
import ast.type.Type;
import visitor.Visitor;

import java.util.List;

public class FunctionDefinition extends AbstractASTNode implements Definition{

    private String name;
    private Type type;
    private int scope;
    private List<VarDefinition> bodyVarDefinitions;
    private List<Statement> statements;
    private int bytesLocalVars;
    private boolean hasReturn;

    public FunctionDefinition(int line,int column, String name, Type type, List<VarDefinition> varDefs,List<Statement> statements){
        super(line,column);
        this.name = name;
        this.type = type;
        this.bodyVarDefinitions = varDefs;
        this.statements = statements;
    }

    @Override
    public String getName() {
        return name;
    }

    @Override
    public Type getType() {
        return type;
    }

    @Override
    public void setScope(int scope) {
        this.scope = scope;
    }

    @Override
    public int getScope() {
        return scope;
    }

    public List<VarDefinition> getBodyVarDefinitions() {
        return bodyVarDefinitions;
    }

    public List<Statement> getStatements() {
        return statements;
    }

    public void setHasReturn(boolean hasReturn) {
        this.hasReturn = hasReturn;
    }

    public boolean hasReturn() {
        return hasReturn;
    }

    @Override
    public <TP, TR> TR accept(Visitor<TP, TR> v, TP param) { return v.visit(this,param); }

    public int getBytesLocalVars() {
        return bytesLocalVars;
    }

    public void setBytesLocalVars(int bytesLocalVars) {
        this.bytesLocalVars = bytesLocalVars;
    }
}
