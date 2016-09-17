require "rake"
require_relative '../../lib/covalence'

shared_context "rake" do
  let(:rake)      { Rake::Application.new }
  let(:task_name) { self.class.description }
  let(:task_root) { Covalence::GEM_ROOT }

  subject         { rake[task_name] }

  def file_globs_to_paths(globs)
    [*globs].map { |glob| Dir.glob(File.absolute_path(glob, task_root)) }.flatten
  end

  before do
    Rake.application = rake
    @task_files = task_files || "rake/*.{rb,rake}"
    task_paths = file_globs_to_paths(@task_files)

    task_paths.each { |path| Rake.application.add_import(path) }
    Rake.application.load_imports
  end
end
