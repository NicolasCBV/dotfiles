function javatest --wraps='mvn clean test' --description 'alias javatest=mvn clean test'
  mvn clean test $argv
        
end
