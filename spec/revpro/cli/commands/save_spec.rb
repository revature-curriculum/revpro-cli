RSpec.describe Revpro::CLI::Commands::Save  do
  let(:path) { File.expand_path("spec/fixtures/lab-repo") }
  # let(:manifest_path) { File.expand_path("#{path}/.codelab/manifest.yml") }
  # let(:manifest ) {YAML.load_file(manifest_path) } 
  # let(:metadata) {YAML.load_file("spec/fixtures/lab-repo/.codelab/revpro.yml") }
  # let(:revpro_lab) {described_class.new(path: path, manifest_path: manifest_path) }
  # # let(:output) { StringIO.new }
  # # let(:input) { StringIO.new }
  # let(:cli) { Revpro::CLI.new(output: output, input: input) }

  before(:each) do
    subject.call(lab_path: path)    
  end

  describe "#lab" do
    it "is a revpro codelab instance" do
      expect(subject.lab).to be_a(Revpro::CLI::Codelabs::Revpro)
    end
  end

  describe "#save" do
    it 'calls #save on the underlying code lab instance' do
      expect(subject.lab).to receive(:save)
      subject.save
    end
  end
end 