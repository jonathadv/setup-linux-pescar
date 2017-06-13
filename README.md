# Setup Linux Pescar

> This script sets up the Projeto Pescar Procempa's machines in order to avoid the students to do that in their first class.

> Customized for Linux Mint 18

```bash
# This script should:
# - Set HTTP_PROXY variables.
# - Set apt-get proxy.
# - Install Open SSH Server.
# - Update/Install some packages.
# - Update Firefox profile.
#
#              CHANGE HISTORY
# 3.3 (12 Jun 2017) - Changes license from GPL to MIT. Changed size of Zenity window
# 3.2 (11 Jun 2017) - Improving log messages and updating script to support Mint 18
# 3.1.1 (05 Jun 2016) - Removed Proxy information (in order to public the source)
# 3.1 (05 Jun 2016) - Added again the functions to set proxy to Firefox and Chormium. Added Zenity to display the options sbox
# 3.0 (25 May 2016) - Refectored all functions. Removed functions to set proxy to Firefox and Chormium
# 2.0 (20 May 2015) - Recreated the functions to set proxy to browsers and added its options to menu
# 1.3 (15 May 2015) - Fixed double execution error when executing sudo via 'sudo -S'
# 1.2 (14 May 2015) - Fixed error in some functions and improved them as well
# 1.1 (14 May 2015) - Added dialog as default UI
# 1.0 (08 Jun 2014) - First version
```