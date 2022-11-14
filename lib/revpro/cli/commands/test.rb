class Revpro::CLI::Commands::Test < Revpro::CLI::Command
    desc "Run the test suite for a lab."
    argument :lab_path, desc: "Path to a lab directory."

    example [      
      "lab-1          # Start lab-1 from within the root directory",
      "topic-1/lab-1  # Start lab-1 in folder topic-1"
    ]
    
    def call(lab_path: ".", **)
      lab_path = "#{File.expand_path(lab_path.strip)}"
      pom_path = "#{lab_path}/pom.xml"
      if File.exists?(pom_path)
        test_run = system("mvn test -f #{pom_path}")
      else
        puts "No lab found at #{lab_path}"
      end
    end
end