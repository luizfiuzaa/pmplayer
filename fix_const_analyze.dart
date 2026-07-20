import 'dart:io';

void main() {
  final result = Process.runSync('flutter', ['analyze']);
  final lines = result.stdout.toString().split('\n');
  
  for (var line in lines) {
    if (line.contains('invalid_constant') || line.contains('non_constant_list_element') || line.contains('undefined_identifier')) {
      final parts = line.split(' • ');
      if (parts.length < 3) continue;
      final fileLoc = parts[2].split(':');
      if (fileLoc.length < 2) continue;
      
      final filePath = fileLoc[0];
      final lineNum = int.tryParse(fileLoc[1]);
      if (lineNum == null) continue;
      
      final file = File(filePath);
      if (!file.existsSync()) continue;
      
      final fileLines = file.readAsLinesSync();
      var targetLine = fileLines[lineNum - 1];
      if (targetLine.contains('const ')) {
        fileLines[lineNum - 1] = targetLine.replaceFirst('const ', '');
        file.writeAsStringSync(fileLines.join('\n'));
      }
    }
  }
}
