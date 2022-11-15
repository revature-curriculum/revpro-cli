# frozen_string_literal: true

RSpec.describe Revpro::CLI::Codelabs::Revpro do
  let(:path) { File.expand_path("spec/fixtures/lab-repo") }
  let(:manifest) { YAML.load_file("#{path}/.codelab/manifest.yml") }
  let(:metadata) { YAML.load_file("#{path}/.codelab/revpro.yml") }
  let(:revpro_lab) { described_class.new(path: path) }

  context "with a manifest.yml and a revpro.yml" do
    it "has a path" do
      expect(revpro_lab.path).to eq(path)
    end

    it "has a manifest" do
      expect(revpro_lab.manifest).to eq(manifest)
    end

    it "has a metadata" do
      expect(revpro_lab.metadata).to eq(metadata)
    end
  end

  context "with a git repo" do
    describe "#repo" do
      it "returns a Git::Base object" do
        expect(revpro_lab.repo).to be_a(Git::Base)
      end
    end
  end

  describe "#save" do
    it "saves the current state of the repo" do
      File.write("#{path}/LAB_CHANGE", "Sample change")
      expect(revpro_lab.repo).to receive(:add).with(all: true)
      expect(revpro_lab.repo).to receive(:commit)
      expect(revpro_lab.repo).to receive(:push)
      
      revpro_lab.save
      
      expect(revpro_lab.repo.status.changed).to be_empty
    end
  end
end
