# Compiler Implementation using Flex and Bison

This project is a step-by-step implementation of a simple compiler using **Flex** (for lexical analysis) and **Bison** (for parsing). The project was developed in four incremental phases:

## Phases

1. **Symbol Table**  
   Implemented a basic symbol table to store and manage identifiers and their attributes.

2. **Lexical Analysis**  
   Used Flex to tokenize the source code, identifying keywords, operators, literals, and identifiers.

3. **Syntax and Semantic Analysis**  
   Used Bison to define grammar rules and perform syntax analysis. Included semantic checks like type validation and declaration checks.

4. **Intermediate Code Generation (ICG)**  
   Generated intermediate representation (e.g., three-address code) for further processing or optimization.
