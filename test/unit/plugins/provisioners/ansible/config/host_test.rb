require_relative "../../../../base"
require_relative "../../support/shared/config"
require_relative "shared"

require Vagrant.source_root.join("plugins/provisioners/ansible/config/host")

describe VagrantPlugins::Ansible::Config::Host, :skip_windows => true do
  include_context "unit"

  subject { described_class.new }

  let(:machine) { double("machine", env: Vagrant::Environment.new) }
  let(:existing_file) { File.expand_path(__FILE__) }
  let(:non_existing_file) { "/this/does/not/exist" }

  it "supports a list of options" do
    supported_options = %w( ask_sudo_pass
                            ask_vault_pass
                            extra_vars
                            force_remote_user
                            galaxy_command
                            galaxy_role_file
                            galaxy_roles_path
                            groups
                            host_key_checking
                            host_vars
                            inventory_path
                            limit
                            playbook
                            raw_arguments
                            raw_ssh_args
                            skip_tags
                            start_at_task
                            sudo
                            sudo_user
                            tags
                            vault_password_file
                            verbose )

    expect(get_provisioner_option_names(described_class)).to eql(supported_options)
  end

  describe "default options handling" do
    it_behaves_like "options shared by both Ansible provisioners"

    it "assigns default values to unset host-specific options" do
      subject.finalize!

      expect(subject.ask_sudo_pass).to be_false
      expect(subject.ask_vault_pass).to be_false
      expect(subject.force_remote_user).to be_true
      expect(subject.host_key_checking).to be_false
      expect(subject.raw_ssh_args).to be_nil
    end
  end

  describe "force_remote_user option" do
    it_behaves_like "any VagrantConfigProvisioner strict boolean attribute", :force_remote_user, true
  end
  describe "host_key_checking option" do
    it_behaves_like "any VagrantConfigProvisioner strict boolean attribute", :host_key_checking, false
  end
  describe "ask_sudo_pass option" do
    it_behaves_like "any VagrantConfigProvisioner strict boolean attribute", :ask_sudo_pass, false
  end
  describe "ask_vault_pass option" do
    it_behaves_like "any VagrantConfigProvisioner strict boolean attribute", :ask_sudo_pass, false
  end

  describe "#validate" do
    before do
      subject.playbook = existing_file
    end

    it_behaves_like "an Ansible provisioner", "", "remote"

    it "returns an error if the playbook file does not exist" do
      subject.playbook = non_existing_file
      subject.finalize!

      result = subject.validate(machine)
      expect(result["ansible remote provisioner"]).to eql([
        I18n.t("vagrant.provisioners.ansible.errors.playbook_path_invalid",
               path: non_existing_file, system: "host")
      ])
    end

    it "returns an error if galaxy_role_file is specified, but does not exist" do
      subject.galaxy_role_file = non_existing_file
      subject.finalize!

      result = subject.validate(machine)
      expect(result["ansible remote provisioner"]).to eql([
        I18n.t("vagrant.provisioners.ansible.errors.galaxy_role_file_invalid",
               path: non_existing_file, system: "host")
      ])
    end

    it "returns an error if inventory_path is specified, but does not exist" do
      subject.inventory_path = non_existing_file
      subject.finalize!

      result = subject.validate(machine)
      expect(result["ansible remote provisioner"]).to eql([
        I18n.t("vagrant.provisioners.ansible.errors.inventory_path_invalid",
               path: non_existing_file, system: "host")
      ])
    end

    it "returns an error if vault_password_file is specified, but does not exist" do
      subject.vault_password_file = non_existing_file
      subject.finalize!

      result = subject.validate(machine)
      expect(result["ansible remote provisioner"]).to eql([
        I18n.t("vagrant.provisioners.ansible.errors.vault_password_file_invalid",
               path: non_existing_file, system: "host")
      ])
    end

    it "returns an error if the raw_ssh_args is of the wrong data type" do
      subject.raw_ssh_args = { arg1: 1, arg2: "foo" }
      subject.finalize!

      result = subject.validate(machine)
      expect(result["ansible remote provisioner"]).to eql([
        I18n.t("vagrant.provisioners.ansible.errors.raw_ssh_args_invalid",
               type:  subject.raw_ssh_args.class.to_s,
               value: subject.raw_ssh_args.to_s)
      ])
    end

    it "converts a raw_ssh_args option defined as a String into an Array" do
      subject.raw_arguments = "-o ControlMaster=no"
      subject.finalize!

      result = subject.validate(machine)
      expect(subject.raw_arguments).to eql(["-o ControlMaster=no"])
    end

    it "it collects and returns all detected errors" do
      subject.playbook = non_existing_file
      subject.inventory_path = non_existing_file
      subject.extra_vars = non_existing_file
      subject.finalize!

      result = subject.validate(machine)
      expect(result["ansible remote provisioner"]).to include(
        I18n.t("vagrant.provisioners.ansible.errors.playbook_path_invalid",
               path: non_existing_file, system: "host"))
      expect(result["ansible remote provisioner"]).to include(
        I18n.t("vagrant.provisioners.ansible.errors.extra_vars_invalid",
               type:  subject.extra_vars.class.to_s,
               value: subject.extra_vars.to_s))
      expect(result["ansible remote provisioner"]).to include(
        I18n.t("vagrant.provisioners.ansible.errors.inventory_path_invalid",
               path: non_existing_file, system: "host"))
    end

  end

end
