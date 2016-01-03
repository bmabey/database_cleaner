require File.dirname(__FILE__) + '/../../spec_helper'
require 'moped'
require 'database_cleaner/moped/truncation'
require File.dirname(__FILE__) + '/moped_examples'

module DatabaseCleaner
  module Moped

    describe Truncation do
      let(:args) {{}}
      let(:truncation) do
        truncation = described_class.new(args)
        truncation.db = 'database_cleaner_specs'
        truncation
      end
      #doing this in the file root breaks autospec, doing it before(:all) just fails the specs
      before(:all) do 
        @session = ::Moped::Session.new(['127.0.0.1:27017'], database: 'database_cleaner_specs')
      end

      after(:each) do
        @session.drop
      end

      def ensure_counts(expected_counts)
        # I had to add this sanity_check garbage because I was getting non-determinisc results from mongo at times..
        # very odd and disconcerting...
        expected_counts.each do |model_class, expected_count|
          actual_count = model_class.count
          actual_count.should equal(expected_count), "#{model_class} expected to have a count of #{expected_count} but was #{actual_count}"
        end
      end

      def create_widget(attrs={})
        MopedTest::Widget.new({:name => 'some widget'}.merge(attrs)).save!
      end

      def create_gadget(attrs={})
        MopedTest::Gadget.new({:name => 'some gadget'}.merge(attrs)).save!
      end

      def create_system(attrs={})
        MopedTest::System.new({:name => 'some system'}.merge(attrs)).save!
      end

      it "truncates all collections by default" do
        create_widget
        create_gadget
        create_system
        ensure_counts(MopedTest::Widget => 1, MopedTest::Gadget => 1, MopedTest::System => 1)
        truncation.clean
        ensure_counts(MopedTest::Widget => 0, MopedTest::Gadget => 0, MopedTest::System => 0)
      end

      context "when collections are provided to the :only option" do
        let(:args) {{:only => ['MopedTest::Widget']}}
        it "only truncates the specified collections" do
          create_widget
          create_gadget
          ensure_counts(MopedTest::Widget => 1, MopedTest::Gadget => 1)
          truncation.clean
          ensure_counts(MopedTest::Widget => 0, MopedTest::Gadget => 1)
        end
      end

      context "when collections are provided to the :except option" do
        let(:args) {{:except => ['MopedTest::Widget']}}
        it "truncates all but the specified collections" do
          create_widget
          create_gadget
          ensure_counts(MopedTest::Widget => 1, MopedTest::Gadget => 1)
          truncation.clean
          ensure_counts(MopedTest::Widget => 1, MopedTest::Gadget => 0)
        end
      end

    end

  end
end
