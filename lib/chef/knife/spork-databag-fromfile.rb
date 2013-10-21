require 'chef/knife'
require 'knife-spork/runner'
require 'json'

module KnifeSpork
  class SporkDataBagFromFile < Chef::Knife
    include KnifeSpork::Runner

    deps do
      require 'chef/knife/data_bag_from_file'
    end

    banner 'knife data bag from file BAG FILE|FOLDER [FILE|FOLDER..] (options)'

    option :secret,
           :short => "-s SECRET",
           :long  => "--secret ",
           :description => "The secret key to use to encrypt data bag item values"

    option :secret_file,
           :long => "--secret-file SECRET_FILE",
           :description => "A file containing the secret key to use to encrypt data bag item values"

    option :all,
           :short => "-a",
           :long  => "--all",
           :description => "Upload all data bags"

    def run
      self.config = Chef::Config.merge!(config)

      @object_name = @name_args.first

      if config[:all] == true
        test = Chef::Knife::DataBagFromFile.new
        test.config[:verbosity] = 3
        databags = test.send(:find_all_data_bags)
        databags.each do |bag|
          test.send(:find_all_data_bag_items,bag).each do |item|
            @object_name = bag
            @object_secondary_name = item.split("/").last
            run_plugins(:before_databagfromfile)
            begin
              pre_databag = load_databag_item(@object_name, @object_secondary_name.gsub(".json",""))
            rescue
              pre_databag = {}
            end
            databag_from_file([@object_name,@object_secondary_name])
            post_databag = load_databag_item(@object_name, @object_secondary_name.gsub(".json",""))
            @object_difference = json_diff(pre_databag,post_databag).to_s
            run_plugins(:after_databagfromfile)
          end
        end

      else
        @name_args[1..-1].each do |arg|
            @object_secondary_name = arg
            run_plugins(:before_databagfromfile)
            begin
              pre_databag = load_databag_item(@object_name, @object_secondary_name.gsub(".json",""))
            rescue
              pre_databag = {}
            end
            databag_from_file
            post_databag = load_databag_item(@object_name, @object_secondary_name.gsub(".json",""))
            @object_difference = json_diff(pre_databag,post_databag).to_s
            run_plugins(:after_databagfromfile)
        end
      end
    end

    private
    def databag_from_file(data_bag_names=nil)
      dbff = Chef::Knife::DataBagFromFile.new
      dbff.name_args = data_bag_names || @name_args
      dbff.config[:editor] = config[:editor]
      dbff.config[:secret] = config[:secret]
      dbff.config[:secret_file] = config[:secret_file]
      dbff.run
    end
  end
end
