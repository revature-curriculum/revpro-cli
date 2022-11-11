module Revpro::CLI::Commands
  class Start < Dry::CLI::Command
    desc "Start on lab."
    argument :lab_address, required: true, desc: "Path to a lab repository."
    argument :lab_path, required: false, desc: "Path to a lab directory."
    
    example [      
      "http://github.com/sample-org/sample-labs          # Start the labs located at that repository URL",
      "sample-org/sample-labs                            # Start the labs located at on Github.com",
    ]
    
    def call(lab_address: nil, lab_path: "", **)
      lab_path = File.basename(lab_address) if lab_path.empty?
        
      if File.exists?(lab_path)
        puts "Lab already exists at #{lab_path}"
        return
      end
      
      lab_path = File.expand_path(lab_path.strip)

      lab_address = "git@github.com:/#{lab_address}" unless lab_address =~ URI::regexp || lab_address.start_with?("git@github.com")
      system("git clone #{lab_address} #{lab_path}")
    end  
  end
end