# Uncomment this line to define a global platform for your project
# platform :ios, "6.0"

pod 'NewRelicAgent'

post_install do |installer|
    installer.project.targets.each do |target|
        target.build_configurations.each do |configuration|
            target.build_settings(configuration.name)['ARCHS'] = 'armv7 armv7s'
        end
    end
end