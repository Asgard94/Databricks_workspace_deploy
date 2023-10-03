# Databricks Workspace Deployment
## Repo Structure
* **src/deploy [folder]:** Notebooks/Workflows's source code parent folder. Inside there is the following structure:
  * **python:** Directory for Python base code Notebooks.
  * **scala:** Directory for Scala base code Notebooks.
  * **workflows:** Directory for Workflows JSON definition.
* **util/deploy [folder]:** Folder with configuration files for objects deployment:
  * **notebook.json:** File with JSON Object array containing variables used for each new/modified Notebook.
  * **workflows.json:** File with JSON Object array containing variables used for each new/modified Workflow.
  * **deploy.sh:** Bash script with source code used for Databricks deployment.
  * **jobs [folder] (OPTIONAL):** Folder with **job.json** file which contains each new/modified Workflow.
