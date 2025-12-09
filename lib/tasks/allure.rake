namespace :allure do
  desc "Generate Allure report from test results"
  task :generate do
    require "open3"

    allure_results_dir = "allure-results"

    unless Dir.exist?(allure_results_dir) && !Dir.empty?(allure_results_dir)
      puts "No Allure results found in #{allure_results_dir}"
      puts "Run your tests first to generate Allure results"
      exit 1
    end

    puts "Generating Allure report from #{allure_results_dir}..."

    # Check if allure command is available
    allure_cmd = `which allure 2>/dev/null`.chomp
    if allure_cmd.empty?
      puts "Allure CLI not found. Installing..."
      puts "Please install Allure CLI:"
      puts "  macOS: brew install allure"
      puts "  Linux: See https://docs.qameta.io/allure/#_installing_a_commandline"
      puts "  Or download from: https://github.com/allure-framework/allure2/releases"
      exit 1
    end

    system("#{allure_cmd} generate #{allure_results_dir} --clean -o allure-report")

    if $?.success?
      puts "Allure report generated successfully in allure-report/"
      puts "View it with: rake allure:open"
    else
      puts "Failed to generate Allure report"
      exit 1
    end
  end

  desc "Open Allure report in browser"
  task :open do
    require "open3"

    unless Dir.exist?("allure-report")
      puts "Allure report not found. Generating..."
      Rake::Task["allure:generate"].invoke
    end

    allure_cmd = `which allure 2>/dev/null`.chomp
    if allure_cmd.empty?
      puts "Allure CLI not found. Please install it first."
      exit 1
    end

    puts "Opening Allure report in browser..."
    puts "Press Ctrl+C to stop the server"

    system("#{allure_cmd} open allure-report")
  end

  desc "Serve Allure report (generates if needed)"
  task serve: :generate do
    Rake::Task["allure:open"].invoke
  end

  desc "Clean Allure results and reports"
  task :clean do
    puts "Cleaning Allure results and reports..."
    FileUtils.rm_rf("allure-results")
    FileUtils.rm_rf("allure-report")
    puts "Cleaned!"
  end
end
