class LSystem {
  String sentence;
  Rule[] ruleset;
  int generation;
  
  LSystem(String axiom, Rule[] r) {
    sentence = axiom;
    ruleset = r;
    generation = 0;
  }
  
  void generate() {
    StringBuffer nextgen = new StringBuffer();
    for (int i=0; i<sentence.length(); i++) {
      char curr = sentence.charAt(i);
      String replace = "" + curr;
      
      for (int j=0; j<ruleset.length; j++) {
        char a = ruleset[j].getA();
        if (a == curr) {
          replace = ruleset[j].getB();
          break;
        }
      }
      
      nextgen.append(replace);
    }
    
    sentence = nextgen.toString();
    generation++;
  }
  
  String getSentence() {
    return sentence;
  }
  
  int getGeneration() {
    return generation;
  }
}
