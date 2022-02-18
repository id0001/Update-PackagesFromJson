# Update-PackagesFromjson
Update nuget packages in visual studio from a json file.

# Instructions

Run from inside visual studio.
Open the 'Package manager console' and run the script from the location you put it in.  
eg: C:\Update-PackagesFromJson.ps1 -Search "my.package.v1" -Json C:\my-packages.json

## Json
```  
{
  "package1": ["relative-project-path", "relative-project-path"],
  "package2": ["relative-project-path", "relative-project-path"]
}
```

## Usage
  Update-PackagesFromJson -Search \<partial name of the package\> -Json \<path to json file\> [-Force]

## Options
- **-Search:** A search string for the package name. Can be a partial name.
- **-Json:** The path to the json file.
- **-Force:** Don't ask for confirmation when set to true.
