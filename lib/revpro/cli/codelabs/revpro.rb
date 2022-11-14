module Revpro::CLI::Codelabs
  class Revpro < Revpro::CLI::Codelab
    
    def initialize(path: ".", manifest_path: ".codelab/manifest.yml")
      @path = File.expand_path(path)
      @manifest = YAML.read(File.expand_path("#{@path}/#{@manifest_path}"))
    end

    def metadata
      binding.pry
      @metadata ||= YAML.read(File.expand_path(@manifest["template"]))
    end
  end
end