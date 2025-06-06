#!/usr/bin/env python3
"""
YAML Configuration Parser for Dotfiles
Converts YAML configuration to shell variables that can be sourced by bash scripts.
"""

import sys
import os
import yaml
from pathlib import Path

def load_yaml_config(config_path):
    """Load and parse YAML configuration file."""
    try:
        with open(config_path, 'r') as file:
            return yaml.safe_load(file)
    except FileNotFoundError:
        print(f"Error: Configuration file not found: {config_path}", file=sys.stderr)
        return None
    except yaml.YAMLError as e:
        print(f"Error: Invalid YAML in {config_path}: {e}", file=sys.stderr)
        return None

def merge_configs(base_config, profile_config):
    """Merge profile configuration with base configuration."""
    if not base_config:
        return profile_config
    if not profile_config:
        return base_config
    
    merged = base_config.copy()
    
    # Simple deep merge for nested dictionaries
    def deep_merge(dict1, dict2):
        for key, value in dict2.items():
            if key in dict1 and isinstance(dict1[key], dict) and isinstance(value, dict):
                deep_merge(dict1[key], value)
            elif key in dict1 and isinstance(dict1[key], list) and isinstance(value, list):
                # For lists, extend rather than replace
                dict1[key].extend(value)
            else:
                dict1[key] = value
    
    deep_merge(merged, profile_config)
    return merged

def flatten_package_list(packages_dict):
    """Flatten nested package structure into simple lists."""
    all_packages = []
    
    def extract_packages(obj):
        if isinstance(obj, list):
            all_packages.extend(obj)
        elif isinstance(obj, dict):
            for value in obj.values():
                extract_packages(value)
    
    extract_packages(packages_dict)
    return all_packages

def config_to_shell_vars(config):
    """Convert YAML config to shell variable assignments."""
    shell_vars = []
    
    # Git configuration
    if 'git' in config:
        git_config = config['git']
        if 'name' in git_config:
            shell_vars.append(f'GIT_NAME="{git_config["name"]}"')
        if 'email' in git_config:
            shell_vars.append(f'GIT_EMAIL="{git_config["email"]}"')
        if 'editor' in git_config:
            shell_vars.append(f'GIT_EDITOR="{git_config["editor"]}"')
        if 'auto_setup_ssh' in git_config:
            shell_vars.append(f'AUTO_SETUP_GIT_SSH="{str(git_config["auto_setup_ssh"]).lower()}"')
    
    # SSH configuration
    if 'ssh' in config:
        ssh_config = config['ssh']
        if 'key_type' in ssh_config:
            shell_vars.append(f'SSH_KEY_TYPE="{ssh_config["key_type"]}"')
        if 'auto_configure_github' in ssh_config:
            shell_vars.append(f'AUTO_CONFIGURE_GITHUB_SSH="{str(ssh_config["auto_configure_github"]).lower()}"')
    
    # Packages
    if 'packages' in config and 'homebrew' in config['packages']:
        homebrew = config['packages']['homebrew']
        
        if 'formulas' in homebrew:
            formulas = flatten_package_list(homebrew['formulas'])
            shell_vars.append(f'HOMEBREW_FORMULAS="{" ".join(formulas)}"')
        
        if 'casks' in homebrew:
            casks = flatten_package_list(homebrew['casks'])
            shell_vars.append(f'HOMEBREW_CASKS="{" ".join(casks)}"')
    
    # QuickLook plugins
    if 'quicklook' in config and 'plugins' in config['quicklook']:
        plugins = config['quicklook']['plugins']
        shell_vars.append(f'QUICKLOOK_PLUGINS="{" ".join(plugins)}"')
    
    # MAS (Mac App Store) apps
    if 'mas_apps' in config:
        mas_apps = config['mas_apps']
        if isinstance(mas_apps, list):
            # Format: "id:name id:name"
            mas_entries = []
            for app in mas_apps:
                if isinstance(app, dict) and 'id' in app and 'name' in app:
                    mas_entries.append(f"{app['id']}:{app['name']}")
            if mas_entries:
                shell_vars.append(f'MAS_APPS="{" ".join(mas_entries)}"')
    
    # System settings
    if 'system' in config:
        system_config = config['system']
        if 'setup_macos_defaults' in system_config:
            shell_vars.append(f'SETUP_MACOS_DEFAULTS="{str(system_config["setup_macos_defaults"]).lower()}"')
        if 'skip_xcode' in system_config:
            shell_vars.append(f'SKIP_XCODE="{str(system_config["skip_xcode"]).lower()}"')
    
    # Xcode settings
    if 'xcode' in config:
        xcode_config = config['xcode']
        if 'skip_install' in xcode_config:
            shell_vars.append(f'SKIP_XCODE="{str(xcode_config["skip_install"]).lower()}"')
        if 'setup_templates' in xcode_config:
            shell_vars.append(f'SETUP_XCODE_TEMPLATES="{str(xcode_config["setup_templates"]).lower()}"')
    
    # Skip settings
    if 'skip' in config:
        skip_config = config['skip']
        for key, value in skip_config.items():
            var_name = f'SKIP_{key.upper()}'
            shell_vars.append(f'{var_name}="{str(value).lower()}"')
    
    # Environment settings
    if 'environments' in config:
        env_config = config['environments']
        if 'python' in env_config:
            python_config = env_config['python']
            if 'skip_install' in python_config:
                shell_vars.append(f'SKIP_PYTHON_INSTALL="{str(python_config["skip_install"]).lower()}"')
            if 'versions' in python_config:
                shell_vars.append(f'PYTHON_VERSIONS="{" ".join(python_config["versions"])}"')
        
        if 'node' in env_config:
            node_config = env_config['node']
            if 'skip_install' in node_config:
                shell_vars.append(f'SKIP_NODE_INSTALL="{str(node_config["skip_install"]).lower()}"')
            if 'version' in node_config:
                shell_vars.append(f'NODE_VERSION="{node_config["version"]}"')
    
    # Terminal settings
    if 'terminal' in config:
        terminal_config = config['terminal']
        for key, value in terminal_config.items():
            var_name = f'{key.upper()}'
            if isinstance(value, bool):
                shell_vars.append(f'{var_name}="{str(value).lower()}"')
            else:
                shell_vars.append(f'{var_name}="{value}"')
    
    # Machine profile
    if 'machine_profile' in config:
        shell_vars.append(f'MACHINE_PROFILE="{config["machine_profile"]}"')
    
    # Minimal packages setting
    if 'minimal_packages' in config:
        shell_vars.append(f'MINIMAL_PACKAGES="{str(config["minimal_packages"]).lower()}"')
    
    return shell_vars

def main():
    """Main function to parse YAML config and output shell variables."""
    if len(sys.argv) != 2:
        print("Usage: yaml_parser.py <profile_name>", file=sys.stderr)
        sys.exit(1)
    
    profile_name = sys.argv[1]
    script_dir = Path(__file__).parent.parent
    
    # Load base configuration
    base_config_path = script_dir / ".dotfiles.yaml"
    base_config = load_yaml_config(base_config_path)
    
    # Load profile configuration
    profile_config_path = script_dir / f".dotfiles.{profile_name}.yaml"
    profile_config = load_yaml_config(profile_config_path)
    
    if not base_config and not profile_config:
        print("Error: Could not load any configuration files", file=sys.stderr)
        sys.exit(1)
    
    # Merge configurations
    merged_config = merge_configs(base_config, profile_config)
    
    # Convert to shell variables
    shell_vars = config_to_shell_vars(merged_config)
    
    # Output shell variables
    for var in shell_vars:
        print(var)

if __name__ == "__main__":
    main()