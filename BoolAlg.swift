//assisted by ChatGPT
import Foundation

enum Token {
    case variable(String)
    case operatorSymbol(String)
    case parenthesis(String)
}

class TreeNode {
    var value: Token
    var left: TreeNode?
    var right: TreeNode?

    init(value: Token, left: TreeNode? = nil, right: TreeNode? = nil) {
        self.value = value
        self.left = left
        self.right = right
    }
}

func tokenize(_ expression: String) -> [Token] {
    // Define recognized operators and their textual representations
    let operators = ["∧", "∨", "¬", "⊕", "=", "≠", "→", "⊤", "⊥", "(", ")"]
    let textOperators = ["AND": "∧", "OR": "∨", "NOT": "¬", "XOR": "⊕", "EQUAL": "=", "NOTEQUAL": "≠", "IMPLY": "→", "TRUE": "⊤", "FALSE": "⊥"]

    var tokens = [Token]() // Initialize an empty array to store the tokens
    var currentToken = ""  // String to build up the current token

    // Iterate through each character in the expression
    for char in expression {
        if char.isWhitespace {
            // If the character is a whitespace, process the current token if it's not empty
            if !currentToken.isEmpty {
                // Append the created token to the tokens list and reset currentToken
                tokens.append(createToken(from: currentToken, textOperators: textOperators))
                currentToken = ""
            }
        } else if operators.contains(String(char)) {
            // If the character is an operator, process the current token and add the operator
            if !currentToken.isEmpty {
                // Append the created token to the tokens list
                tokens.append(createToken(from: currentToken, textOperators: textOperators))
                currentToken = ""
            }
            // Add the operator as a token
            tokens.append(.operatorSymbol(String(char)))
        } else {
            // If the character is part of a variable or text operator, append it to currentToken
            currentToken.append(char)
        }
    }
    // Add the last token if currentToken is not empty
    if !currentToken.isEmpty {
        tokens.append(createToken(from: currentToken, textOperators: textOperators))
    }
    return tokens // Return the list of tokens
}

// Function to create a token from a given string
func createToken(from string: String, textOperators: [String: String]) -> Token {
    // Check if the string matches any textual operator (e.g., "AND", "OR") after converting it to upper case
    if let symbol = textOperators[string.uppercased()] {
        // If a match is found, return an operator symbol token with the corresponding operator symbol
        return .operatorSymbol(symbol)
    } else {
        // If no match is found, treat the string as a variable and return a variable token
        return .variable(string)
    }
}

// Function to evaluate the parse tree based on the values of variables
func evaluateTree(_ node: TreeNode?, with variableValues: [String: Bool]) -> Bool? {
    // Guard to ensure the current node is not nil. If it is, return nil indicating an evaluation error or end of branch
    guard let node = node else { return nil }

    // Switch on the type of token the node represents
    switch node.value {
    case .variable(let name):
        // If the node is a variable, return its value from the provided dictionary
        return variableValues[name]

    case .operatorSymbol(let symbol):
        // If the node is an operator, evaluate based on the operator type
        switch symbol {
        case "¬":
            // For NOT operator, evaluate the right child (unary operator) and return its negated value
            if let rightValue = evaluateTree(node.right, with: variableValues) {
                return !rightValue
            }
        case "∧":
            // For AND operator, recursively evaluate both children and return the logical AND of their values
            if let leftValue = evaluateTree(node.left, with: variableValues),
               let rightValue = evaluateTree(node.right, with: variableValues) {
                return leftValue && rightValue
            }
        case "∨":
            // For OR operator, recursively evaluate both children and return the logical OR of their values
            if let leftValue = evaluateTree(node.left, with: variableValues),
               let rightValue = evaluateTree(node.right, with: variableValues) {
                return leftValue || rightValue
            }
        case "⊕":
            // For XOR operator, recursively evaluate both children and return true if they are different
            if let leftValue = evaluateTree(node.left, with: variableValues),
               let rightValue = evaluateTree(node.right, with: variableValues) {
                return leftValue != rightValue
            }
        case "=":
            // For EQUAL operator, recursively evaluate both children and return true if they are equal
            if let leftValue = evaluateTree(node.left, with: variableValues),
               let rightValue = evaluateTree(node.right, with: variableValues) {
                return leftValue == rightValue
            }
        case "≠":
            // For NOT EQUAL operator, recursively evaluate both children and return true if they are not equal
            if let leftValue = evaluateTree(node.left, with: variableValues),
               let rightValue = evaluateTree(node.right, with: variableValues) {
                return leftValue != rightValue
            }
        case "→":
            // For IMPLICATION operator, recursively evaluate both children and return true unless left is true and right is false
            if let leftValue = evaluateTree(node.left, with: variableValues),
               let rightValue = evaluateTree(node.right, with: variableValues) {
                return !leftValue || rightValue
            }
        default:
            // For unrecognized operator, return nil indicating an evaluation error
            return nil
        }
    default:
        // If the node is not a variable or operator (which shouldn't happen), return nil
        return nil
    }
    // If the evaluation didn't return in the above cases, return nil
    return nil
}

func parseExpressionToTree(tokens: [Token]) -> TreeNode? {
    var stack: [TreeNode] = []

    for token in tokens {
        switch token {
        case .variable, .operatorSymbol("⊤"), .operatorSymbol("⊥"):
            // Push variables and constants directly onto the stack
            stack.append(TreeNode(value: token))
        case .operatorSymbol:
            // Pop the last two items from the stack and make them children of a new node
            guard let right = stack.popLast() else { return nil }
            let left = stack.popLast() // Left can be nil for unary operators
            let operatorNode = TreeNode(value: token, left: left, right: right)
            stack.append(operatorNode)
        default:
            // Ignore parentheses as they are not needed in RPN
            continue
        }
    }

    // The final item on the stack is the root of the parse tree
    return stack.last
}
func printTree(_ node: TreeNode?, level: Int = 0) {
    guard let node = node else { return }

    // Print the right subtree
    if let right = node.right {
        printTree(right, level: level + 1)
    }

    // Print the current node
    let padding = String(repeating: "   ", count: level)
    let nodeValue = tokenDescription(node.value)
    print("\(padding)\(nodeValue)")

    // Print the left subtree
    if let left = node.left {
        printTree(left, level: level + 1)
    }
}

func tokenDescription(_ token: Token) -> String {
    switch token {
    case .variable(let name):
        return name
    case .operatorSymbol(let symbol):
        return symbol
    case .parenthesis(let symbol):
        return symbol
    }
}

func generateCombinations(for variables: [String]) -> [[String: Bool]] {
    let totalCombinations = Int(pow(2.0, Double(variables.count)))
    var combinations: [[String: Bool]] = []

    for i in 0..<totalCombinations {
        var combination: [String: Bool] = [:]
        for (index, variable) in variables.enumerated() {
            let value = ((i >> index) & 1) == 1
            combination[variable] = value
        }
        combinations.append(combination)
    }

    return combinations
}


// Main Program
print("Enter a boolean expression:")
if let input = readLine() {
    let tokens = tokenize(input)
    if let treeRoot = parseExpressionToTree(tokens: tokens) {
        print("Parse Tree:")
        printTree(treeRoot)

        let variables = Set(tokens.compactMap { if case .variable(let name) = $0 { return name } else { return nil } }).sorted()

        let combinations = generateCombinations(for: variables)

        print((variables + ["Result"]).joined(separator: " | "))

        for combination in combinations {
            let result = evaluateTree(treeRoot, with: combination) ?? false
            let row = variables.map { combination[$0]! ? "T" : "F" } + [result ? "T" : "F"]
            print(row.joined(separator: " | "))
        }
    } else {
        print("Invalid expression or unable to parse")
    }
} else {
    print("Invalid input")
}
