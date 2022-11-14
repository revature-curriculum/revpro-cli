class Revpro::CLI::Commands::Open < Revpro::CLI::Command
  desc "Open a lab in your editor."
  argument :lab_path, desc: "Path to a lab directory."

  example [      
    "lab-1          # Open lab-1 from within the root directory",
    "topic-1/lab-1  # Open lab-1 in folder topic-1"
  ]
  
  def call(lab_path: ".", **)
    lab_path = File.expand_path(lab_path.strip)

    system("#{ENV["EDITOR"]} #{lab_path}")            
  end
end