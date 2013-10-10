require 'spec_helper'
require 'hydra/file_characterization'
require 'hydra/file_characterization/characterizer'

module Hydra

  describe FileCharacterization do

    describe '.characterize' do
      let(:content) { "class Test; end\n" }
      let(:filename) { 'test.rb' }
      subject { Hydra::FileCharacterization.characterize(content, filename, tool_names) }

      describe 'for fits' do
        let(:tool_names) { [:fits] }
        it { should match(/#{'<identity format="Plain text" mimetype="text/plain"'}/) }
      end

      describe 'with configured path' do
        it {
          response = Hydra::FileCharacterization.characterize(content, filename, :fits) do |config|
            config[:fits] = `which fits || which fits.sh`.strip
          end
          expect(response).to match(/#{'<identity format="Plain text" mimetype="text/plain"'}/)
        }
      end

      describe 'with multiple runs' do
        it {
          response_1, response_2, response_3 = Hydra::FileCharacterization.characterize(content, filename, :fits, :fits)
          expect(response_1).to match(/#{'<identity format="Plain text" mimetype="text/plain"'}/)
          expect(response_2).to match(/#{'<identity format="Plain text" mimetype="text/plain"'}/)
          expect(response_3).to be_nil
        }
      end

      describe 'for a bogus tool' do
        let(:tool_names) { [:cookie_monster] }
        it {
          expect {
            subject
          }.to raise_error(Hydra::FileCharacterization::ToolNotFoundError)
        }
      end

      describe 'for a mix of bogus and valid tools' do
        let(:tool_names) { [:fits, :cookie_monster] }
        it {
          expect {
            subject
          }.to raise_error(Hydra::FileCharacterization::ToolNotFoundError)
        }
      end

      describe 'for no tools' do
        let(:tool_names) { nil }
        it { should eq [] }
      end

    end
    describe '.configure' do
      let(:content) { "class Test; end\n" }
      let(:filename) { 'test.rb' }
      around do |example|
        old_tool_path = Hydra::FileCharacterization::Characterizers::Fits.tool_path
        example.run
        Hydra::FileCharacterization::Characterizers::Fits.tool_path = old_tool_path
      end

      it 'without configuration' do
        Hydra::FileCharacterization.configure do |config|
          config.tool_path(:fits, nil)
        end

        expect {
          Hydra::FileCharacterization.characterize(content, filename, :fits)
        }.to raise_error(Hydra::FileCharacterization::UnspecifiedToolPathError)
      end
    end

  end
end