# Uncomment this line to define a global platform for your project
# platform :ios, '8.0'
# Uncomment this line if you're using Swift
# use_frameworks!

platform :ios, ‘8.0’

pod 'mailcore2-ios'
pod 'YTKKeyValueStore'
pod 'MBProgressHUD', '~> 0.9.2'

use_frameworks!
pod 'SnapKit', '~> 0.15.0'

post_install do |installer|  
    installer.pods_project.build_configuration_list.build_configurations.each do |configuration|  
        configuration.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'  
    end  
end