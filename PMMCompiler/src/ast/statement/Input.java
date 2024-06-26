package ast.statement;


import ast.expression.Expression;
import ast.node.AbstractASTNode;
import visitor.Visitor;

public class Input extends AbstractStatement {

    private Expression inputExpression;

    public Input(int line, int column, Expression inputExpression) {
        super(line, column);
        this.inputExpression = inputExpression;
        super.hasReturn = false;
    }

    @Override
    public <TP, TR> TR accept(Visitor<TP, TR> v, TP param) {
        return v.visit(this,param);
    }

    public Expression getInputExpression() {
        return inputExpression;
    }
}
