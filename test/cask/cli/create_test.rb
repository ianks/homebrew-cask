require 'test_helper'

# monkeypatch for testing
class Cask::CLI::Create
  def self.exec_editor(*command)
    editor_commands << command
  end

  def self.reset!
    @editor_commands = []
  end

  def self.editor_commands
    @editor_commands ||= []
  end
end

describe Cask::CLI::Create do
  before { Cask::CLI::Create.reset! }

  after {
    %w[ new-cask additional-cask another-cask feine ].each do |cask|
      path = Cask.path(cask)
      path.delete if path.exist?
    end
  }

  it 'opens the editor for the specified cask' do
    Cask::CLI::Create.run('new-cask')
    Cask::CLI::Create.editor_commands.must_equal [
      [Cask.path('new-cask')]
    ]
  end

  it 'drops a template down for the specified cask' do
    Cask::CLI::Create.run('new-cask')
    template = File.read(Cask.path('new-cask'))
    template.must_equal <<-TEMPLATE.undent
      class NewCask < Cask
        version ''
        sha256 ''

        url 'https://'
        homepage ''
        license :unknown

        app ''
      end
    TEMPLATE
  end

  it 'throws away additional arguments and uses the first' do
    Cask::CLI::Create.run('additional-cask', 'another-cask')
    Cask::CLI::Create.editor_commands.must_equal [
      [Cask.path('additional-cask')]
    ]
  end

  it 'raises an exception when the cask already exists' do
    lambda {
      Cask::CLI::Create.run('caffeine')
    }.must_raise CaskAlreadyCreatedError
  end

  it 'allows creating casks that are substrings of existing casks' do
    Cask::CLI::Create.run('feine')
    Cask::CLI::Create.editor_commands.must_equal [
      [Cask.path('feine')]
    ]
  end

  it "raises an exception when no cask is specified" do
    lambda {
      Cask::CLI::Create.run
    }.must_raise CaskUnspecifiedError
  end
end
