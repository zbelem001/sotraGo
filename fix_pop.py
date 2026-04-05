import re

with open('lib/screens/map_screen.dart', 'r+') as f:
    content = f.read()

    # Find the start of PopScope
    # In map_screen.dart:
    #     bool hasSubState =
    #        _isSearchMode || ...
    #
    #    return PopScope(
    #        canPop: !hasSubState,
    
    # We want to replace `bool hasSubState =\n ... _foundRoutes.isNotEmpty;\n\n return PopScope(... child: Scaffold(`
    # with `return Scaffold(`
    
    pattern = r'bool hasSubState\s*=\s*_isSearchMode \|\|[\s\S]*?child:\s*Scaffold\('
    content = re.sub(pattern, 'return Scaffold(', content)
    
    f.seek(0)
    f.write(content)
    f.truncate()
