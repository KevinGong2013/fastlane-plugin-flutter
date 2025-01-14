require 'fastlane/action'
require_relative '../base/flutter_action_base'
require_relative '../helper/flutter_helper'

module Fastlane
  module Actions
    module SharedValues
      FLUTTER_OUTPUT = :FLUTTER_OUTPUT
    end

    class FlutterBuildAction < Action
      extend FlutterActionBase

      FASTLANE_PLATFORM_TO_BUILD = {
        ios: 'ios',
        android: 'apk',
      }

      def self.run(params)
        # "flutter build" args list.
        build_args = []

        if params[:build]
          build_args.push(params[:build])
        else
          if fastlane_platform = (lane_context[SharedValues::PLATFORM_NAME] ||
                                  lane_context[SharedValues::DEFAULT_PLATFORM])
            build_args.push(FASTLANE_PLATFORM_TO_BUILD[fastlane_platform])
          else
            UI.user_error!('flutter_build action "build" parameter is not ' \
            'specified and cannot be inferred from Fastlane context.')
          end
        end

        if params[:debug]
          build_args.push('--debug')
        end

        if params[:codesign] == false
          build_args.push('--no-codesign')
        end

        if build_number = (params[:build_number] ||
                           lane_context[SharedValues::BUILD_NUMBER])
          build_args.push('--build-number', build_number.to_s)
        end

        if build_name = (params[:build_name] ||
                         lane_context[SharedValues::VERSION_NUMBER])
          build_args.push('--build-name', build_name.to_s)
        end

        if build_flavor = (params[:build_flavor])
          build_args.push('--flavor', build_flavor)
        end

        if target = (params[:target])
          build_args.push('--target', target)
        end

        Helper::FlutterHelper.flutter('build', *build_args) do |status, res|
          if status.success?
            if res =~ /^Built (.*?)(:? \([^)]*\))?\.$/
              lane_context[SharedValues::FLUTTER_OUTPUT] =
                File.absolute_path($1)
            else
              UI.important('Cannot parse built file path from "flutter build"')
            end
          end
          # Tell upstream to NOT ignore error.
          false
        end

        lane_context[SharedValues::FLUTTER_OUTPUT]
      end

      def self.description
        'Run "flutter build" to build a Flutter application'
      end

      def self.category
        :building
      end

      def self.return_value
        'A path to the built file, if available'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :build,
            env_name: 'FL_FLUTTER_BUILD',
            description: 'Type of Flutter build (e.g. apk, appbundle, ios)',
            optional: true,
            type: String,
          ),
          FastlaneCore::ConfigItem.new(
            key: :debug,
            env_name: 'FL_FLUTTER_DEBUG',
            description: 'Build a Debug version of the app if true',
            optional: true,
            type: Boolean,
            default_value: false,
          ),
          FastlaneCore::ConfigItem.new(
            key: :codesign,
            env_name: 'FL_FLUTTER_CODESIGN',
            description: 'Set to false to skip iOS app signing. This may be ' \
            'useful e.g. on CI or when signed later by Fastlane "sigh"',
            optional: true,
            type: Boolean,
          ),
          FastlaneCore::ConfigItem.new(
            key: :build_number,
            env_name: 'FL_FLUTTER_BUILD_NUMBER',
            description: 'Override build number specified in pubspec.yaml',
            optional: true,
            type: Integer,
          ),
          FastlaneCore::ConfigItem.new(
            key: :build_name,
            env_name: 'FL_FLUTTER_BUILD_NAME',
            description: <<-'DESCRIPTION',
              Override build name specified in pubspec.yaml.
              NOTE: for App Store, build name must be in the format of at most 3
                    integeres separated by a dot (".").
            DESCRIPTION
            optional: true,
          ),
          FastlaneCore::ConfigItem.new(
            key: :build_flavor,
            description: <<-'DESCRIPTION',
              Set build flavor.
            DESCRIPTION
            optional: true,
          ),
          FastlaneCore::ConfigItem.new(
            key: :target,
            description: <<-'DESCRIPTION',
              The main entry-point file of the application
            DESCRIPTION
            optional: true
          )
        ]
      end
    end
  end
end
