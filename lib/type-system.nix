{ lib, pkgs }:

let
  # Enhanced type handlers for plist conversion
  typeHandlers = {
    "date" = {
      description = "ISO 8601 date string to datetime object";
      examples = [ "2023-12-25T14:30:00Z" "2023-12-25T14:30:00+05:00" ];
    };

    "data" = {
      description = "Base64-encoded binary data";
      examples = [ "SGVsbG8gV29ybGQ=" "AQIDBA==" ];
    };

    "bool" = {
      description = "Boolean value (string to boolean)";
      examples = [ "true" "false" "1" "0" "yes" "no" ];
    };

    "int" = {
      description = "Integer number with precision control";
      examples = [ 42 "42" "-10" ];
    };

    "float" = {
      description = "Floating point number";
      examples = [ 3.14 "3.14159" "-0.5" ];
    };

    "url" = {
      description = "URL object (as string for plist compatibility)";
      examples = [ "https://example.com" "http://localhost:8080" ];
    };

    "uuid" = {
      description = "UUID object (as string for plist compatibility)";
      examples = [ "550e8400-e29b-41d4-a716-446655440000" ];
    };

    "string" = {
      description = "Explicit string conversion";
      examples = [ "hello" 42 ];
    };
  };

  # Generate enhanced type conversion code as a separate file
  typeConversionModule = pkgs.writeTextFile {
    name = "enhanced-type-conversion.py";
    text = ''
      import json
      import base64
      import re
      from datetime import datetime
      
      # Enhanced type handlers with validation
      TYPE_HANDLERS = {
          "date": {
              "converter": lambda v: datetime.fromisoformat(v.replace('Z', '+00:00')),
              "validator": lambda v: isinstance(v, str),
              "description": "ISO 8601 date string to datetime object"
          },
          "data": {
              "converter": lambda v: base64.b64decode(v),
              "validator": lambda v: isinstance(v, str),
              "description": "Base64-encoded binary data"
          },
          "bool": {
              "converter": lambda v: v.lower() in ('true', '1', 'yes') if isinstance(v, str) else bool(v),
              "validator": lambda v: True,
              "description": "Boolean value"
          },
          "int": {
              "converter": lambda v: int(v),
              "validator": lambda v: isinstance(v, (int, str)),
              "description": "Integer number"
          },
          "float": {
              "converter": lambda v: float(v),
              "validator": lambda v: isinstance(v, (int, float, str)),
              "description": "Floating point number"
          },
          "url": {
              "converter": lambda v: str(v),
              "validator": lambda v: isinstance(v, str),
              "description": "URL object (as string)"
          },
          "uuid": {
              "converter": lambda v: str(v),
              "validator": lambda v: isinstance(v, str),
              "description": "UUID object (as string)"
          },
          "string": {
              "converter": lambda v: str(v),
              "validator": lambda v: True,
              "description": "Explicit string conversion"
          }
      }
      
      def convert_with_validation(type_name, value):
          """Convert value with validation"""
          if type_name not in TYPE_HANDLERS:
              raise ValueError(f"Unknown type: {type_name}")
          
          handler = TYPE_HANDLERS[type_name]
          
          # Validate input
          try:
              if not handler["validator"](value):
                  raise ValueError(f"Invalid value for type {type_name}: {value}")
          except Exception as e:
              print(f"warning: validation issue for {type_name}: {e}")
          
          # Convert value
          try:
              return handler["converter"](value)
          except Exception as e:
              print(f"warning: conversion issue for {type_name}: {e}")
              return value
      
      def enhanced_convert_json_to_plist(obj, depth=0, max_depth=50):
          """Enhanced type conversion for plist with depth protection and validation"""
          if depth > max_depth:
              raise ValueError(f"Maximum recursion depth ({max_depth}) exceeded")
          
          if isinstance(obj, dict):
              # Check for explicit type annotations
              if "__type" in obj and "value" in obj:
                  type_name = obj["__type"]
                  value = obj["value"]
                  
                  try:
                      return convert_with_validation(type_name, value)
                  except Exception as e:
                      print(f"warning: type conversion failed for {type_name}: {e}")
                      return value
              
              # Recursively process dict
              result = {}
              for k, v in obj.items():
                  result[k] = enhanced_convert_json_to_plist(v, depth + 1, max_depth)
              return result
          
          elif isinstance(obj, list):
              return [enhanced_convert_json_to_plist(item, depth + 1, max_depth) for item in obj]
          
          else:
              return obj
    '';
  };

  # Generate validation schema for JSON files
  generateJSONSchema = fileConfig: ''
    {
      "type": "object",
      "properties": {
        "files": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "type": {"type": "string", "enum": ["plist"]},
              "format": {"type": "string", "enum": ["xml1", "binary1"]},
              "filename": {"type": "string"},
              "filepath": {"type": "string"},
              "permissions": {"type": "string"}
            },
            "required": ["type", "format", "filename", "filepath", "permissions"]
          }
        }
      },
      "required": ["files"]
    }
  '';

  # Simple validation tool created as an external script to avoid indentation issues
  validationTool = pkgs.writeScriptBin "plist-validator" ''
    #!${pkgs.python3}/bin/python3
    import json
    import sys
    import re
    
    def validate_json_file(file_path):
        try:
            with open(file_path, 'r') as f:
                data = json.load(f)
            
            print("Validating:", file_path)
            
            if 'files' not in data:
                print("error: missing 'files' array")
                return False
            
            if not isinstance(data['files'], list):
                print("error: 'files' must be an array")
                return False
            
            file_count = len(data['files'])
            print("Found", file_count, "file configuration(s)")
            
            all_valid = True
            for i, file_config in enumerate(data['files']):
                filename = file_config.get('filename', 'unnamed')
                print("File", str(i + 1) + ":", filename)
                
                required_fields = ['type', 'format', 'filename', 'filepath', 'permissions']
                for field in required_fields:
                    if field not in file_config:
                        print("error: missing required field:", field)
                        all_valid = False
                    else:
                        print("ok:", field)
                
                if file_config.get('type') == 'plist':
                    format_val = file_config.get('format')
                    if format_val not in ['xml1', 'binary1']:
                        print("warning: unknown format:", format_val)
                    
                    if not filename.endswith('.plist'):
                        print("warning: filename should end with .plist:", filename)
            
            if all_valid:
                print("Validation passed for", file_path)
            else:
                print("Validation failed for", file_path)
            
            return all_valid
            
        except json.JSONDecodeError as e:
            print("error: JSON parsing error:", e)
            return False
        except Exception as e:
            print("error: unexpected error:", e)
            return False
    
    if len(sys.argv) < 2:
        print("Usage: plist-validator <json_file1> [json_file2] ...")
        sys.exit(1)
    
    all_valid = True
    for json_file in sys.argv[1:]:
        if not validate_json_file(json_file):
            all_valid = False
        print()
    
    sys.exit(0 if all_valid else 1)
  '';

in
{
  inherit
    typeHandlers
    typeConversionModule
    generateJSONSchema
    validationTool;
}
