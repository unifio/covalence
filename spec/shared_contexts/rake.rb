require "rake"
require 'pathname'

shared_context "rake" do
  let(:rake)      { Rake::Application.new }
  let(:task_name) { self.class.top_level_description }
  let(:task_path) { "lib/rake/environment" }
  let(:task_root) { Pathname.new("#{Dir.pwd}/ruby") }
  subject         { rake[task_name] }

  def loaded_files_excluding_current_rake_file
    $".reject {|file| file == task_root.join("#{task_path}.rake").to_s }
  end

  before do
    Rake.application = rake
    Rake.application.rake_require(task_path, [task_root.to_s], loaded_files_excluding_current_rake_file)
  end
end
