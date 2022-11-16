class Revpro::CLI::Commands::Start < Revpro::CLI::Command
  desc "Start on lab."
  argument :lab_address, required: true, desc: "Path to a lab repository."
  argument :lab_path, required: false, desc: "Path to a lab directory."
  
  example [      
    "http://github.com/sample-org/sample-labs          # Start the labs located at that repository URL",
    "sample-org/sample-labs                            # Start the labs located at on Github.com",
  ]
  
  def call(lab_address: nil, lab_path: "", **)
    # This will have to check if the lab is already cloned, and if so, just open it.
    code_lab = Revpro::CLI::Codelab.clone(lab_address, lab_path)
  end  
end