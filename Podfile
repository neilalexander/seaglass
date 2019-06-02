platform :osx, '10.13'
inhibit_all_warnings!

target 'Seaglass' do
  use_frameworks!

  pod 'SwiftMatrixSDK', '0.10.12'
  pod 'Down'
  pod 'TSMarkdownParser'
  pod 'Sparkle'
  pod 'LetsMove'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['LD_NO_PIE'] = 'NO'
    end
  end
end
