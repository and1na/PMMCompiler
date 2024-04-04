package ast.type;

import ast.definition.VarDefinition;
import ast.node.ASTNode;
import visitor.Visitor;

import java.util.List;

public class Function extends AbstractType {

    private final Type returnType;
    private final List<VarDefinition> parameters;

    public Function(int line, int column, Type returnType, List<VarDefinition> parameters){
        super(line,column);
        this.returnType = returnType;
        this.parameters = parameters;
    }

    @Override
    public Type parenthesis(List<Type> otherList, ASTNode ast) {

        if(otherList.size() != parameters.size()) return new ErrorType(ast.getLine(), ast.getColumn(),
                "Wrong number of parameters in function call");

        for(int i = 0; i < otherList.size(); i++){
            Type definedParamType = parameters.get(i).getType();
            Type receivedParamType = otherList.get(i);

            if(!receivedParamType.mustPromoteTo(definedParamType, ast).equals(definedParamType)){
                return new ErrorType(ast.getLine(), ast.getColumn(),
                        "Wrong type in parameter nº" + i + " in function call");
            }
        }
        return returnType;
    }

    @Override
    public <TP, TR> TR accept(Visitor<TP, TR> v, TP param) {
        return v.visit(this,param);
    }

    public Type getReturnType() {
        return returnType;
    }

    public List<VarDefinition> getParameters() {
        return parameters;
    }
}
