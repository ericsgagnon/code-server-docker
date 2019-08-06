# code-server-docker  

Work in Progress - image packages code-server (vs code in web browser) with latest versions of go and python, odbc drivers, and oracle oci.

- multistage:
  -  based on official python image for convenience 
  -  golang from official docker image  
  -  oracle oci from oracle-linux stage to download without clickthrough or signin
  -  linux odbc drivers installed 
  -  codercom/coder-server installed by roughly mimicking their dockerfile

TODO:
-  setup convenience parameters/scripts for configuring datasources
-  automate build triggers based on new releases of languages or code-server

