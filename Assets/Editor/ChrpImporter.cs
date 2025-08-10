using UnityEngine;
using UnityEditor;
using System.IO;
using System.Collections.Generic;
using System.Linq;

public class ChrpSongImporter : AssetPostprocessor
{
    private const string fileExtension = ".chrp";

    private static void OnPostprocessAllAssets(string[] importedAssets, string[] deletedAssets, string[] movedAssets, string[] movedFromAssetPaths)
    {
        foreach (string assetPath in importedAssets)
        {
            if (assetPath.EndsWith(fileExtension, System.StringComparison.OrdinalIgnoreCase))
            {
                ProcessChrpFile(assetPath);
            }
        }
    }

    private static void ProcessChrpFile(string assetPath)
    {
        string[] lines = File.ReadAllLines(assetPath);

        Song songData = ScriptableObject.CreateInstance<Song>();
        string dirPath = Path.GetDirectoryName(assetPath) + Path.DirectorySeparatorChar;

        Dictionary<string, string> audioPaths = new();
        int startOfInstruments = ParseHeader(lines, songData, dirPath, audioPaths);

        // Process instrument sections from where the header left off
        Instrument currentInstrument = null;
        for (int i = startOfInstruments; i < lines.Length; i++)
        {
            string line = lines[i];
            string trimmedLine = line.Trim();
            if (string.IsNullOrWhiteSpace(line) || trimmedLine.StartsWith("#")) continue;

            if (trimmedLine.StartsWith("[") && trimmedLine.EndsWith("]"))
            {
                // Save the previous instrument and start a new one
                if (currentInstrument != null)
                {
                    songData.Instruments.Add(currentInstrument);
                }

                string instrumentName = trimmedLine.Substring(1, trimmedLine.Length - 2);
                currentInstrument = new Instrument(instrumentName);

                // Link the audio file to the new instrument
                if (audioPaths.ContainsKey(instrumentName))
                {
                    currentInstrument.Audio = AssetDatabase.LoadAssetAtPath<AudioClip>(audioPaths[instrumentName]);
                    if (currentInstrument.Audio == null)
                    {
                        Debug.LogWarning($"Could not find AudioClip at path: {audioPaths[instrumentName]} for instrument '{instrumentName}'.");
                    }
                }
            }
            else if (currentInstrument != null)
            {
                // This line is rhythm data, parse it and add notes to the current instrument
                currentInstrument.Notes.AddRange(ParseRhythmLine(line, currentInstrument.Notes));
            }
        }
        
        // Add the last instrument
        if (currentInstrument != null)
        {
            songData.Instruments.Add(currentInstrument);
        }

        string outputAssetPath = Path.Combine(Path.GetDirectoryName(assetPath), Path.GetFileNameWithoutExtension(assetPath) + ".asset");
        AssetDatabase.CreateAsset(songData, outputAssetPath);
        AssetDatabase.ImportAsset(outputAssetPath);
        
        Debug.Log($"Successfully imported song file '{assetPath}' and created '{outputAssetPath}'.");
    }

    /// <summary>
    /// Parses the metadata and audio paths from the beginning of the file.
    /// </summary>  
    /// <returns>The index of the first line that is not part of the header.</returns>
    private static int ParseHeader(string[] lines, Song songData, string dirPath, Dictionary<string, string> audioPaths)
    {
        int lineIndex = 0;
        while (lineIndex < lines.Length)
        {
            string line = lines[lineIndex];
            string trimmedLine = line.Trim();

            if (trimmedLine.StartsWith("["))
            {
                return lineIndex;
            }

            if (!string.IsNullOrWhiteSpace(line))
            {
                string[] parts = line.Split(':').Select(s => s.Trim()).ToArray();
                if (parts.Length >= 2)
                {
                    string key = parts[0].ToLower();
                    string value = string.Join(":", parts.Skip(1));

                    switch (key)
                    {
                        case "title": songData.Title = value; break;
                        case "artist": songData.Artist = value; break;
                        case "bpm": int.TryParse(value, out songData.BPM); break;
                        case "bpb": int.TryParse(value, out songData.BPB); break;
                        case "audio":
                            ParseAudioPaths(lines, ref lineIndex, dirPath, songData, audioPaths);
                            break;
                    }
                }
            }
            lineIndex++;
        }
        return lineIndex;
    }

    /// <summary>
    /// Parses the indented audio file paths.
    /// </summary>
    private static void ParseAudioPaths(string[] lines, ref int lineIndex, string dirPath, Song songData, Dictionary<string, string> audioPaths)
    {
        while (lineIndex < lines.Length - 1 && lines[lineIndex + 1].StartsWith("    "))
        {
            lineIndex++;
            string audioLine = lines[lineIndex];
            string[] audioParts = audioLine.Trim().Split(':').Select(s => s.Trim()).ToArray();
            if (audioParts.Length < 2) continue;

            string audioKey = audioParts[0];
            string audioValue = string.Join(":", audioParts.Skip(1));

            if (audioKey == "_")
            {
                songData.Audio = AssetDatabase.LoadAssetAtPath<AudioClip>(dirPath + audioValue);
            }
            else
            {
                audioPaths[audioKey] = dirPath + audioValue;
            }
        }
    }

    /// <summary>
    /// Parses a single line of rhythm data into an array of Note objects.
    /// </summary>
    private static List<Note> ParseRhythmLine(string line, List<Note> existingNotes)
    {
        var newNotes = new List<Note>();
        int beat = existingNotes.Any() ? existingNotes.Max(n => n.Beat) + 1 : 0;
        
        int numTracks = (int)Mathf.Ceil(line.Length / 4.0f);
        for (int track = 0; track < numTracks; track++)
        {
            string trackData = "";
            int startIndex = track * 4;
            if (startIndex < line.Length)
            {
                trackData = line.Substring(startIndex, Mathf.Min(4, line.Length - startIndex));
            }
            string notesStr = trackData.Trim();
            
            if (string.IsNullOrEmpty(notesStr)) continue;

            for (int offset = 0; offset < notesStr.Length; offset++)
            {
                char noteChar = notesStr[offset];
                float subbeat = (float)offset / notesStr.Length;

                if (char.IsDigit(noteChar))
                {
                    int priority = int.Parse(noteChar.ToString());
                    var newNote = new Note(track, beat, subbeat, priority);
                    newNotes.Add(newNote);
                }
                else if (noteChar == '-')
                {
                    var lastNoteOnTrack = existingNotes.Where(n => n.Track == track).LastOrDefault();
                    if (lastNoteOnTrack != null)
                    {
                        float subbeatEnd = subbeat + (1.0f / notesStr.Length);
                        lastNoteOnTrack.Duration = beat - lastNoteOnTrack.Beat + subbeatEnd - lastNoteOnTrack.Subbeat;
                    }
                }
            }
        }
        return newNotes;
    }
}