using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// Represents a song in the game.
/// </summary>
[CreateAssetMenu(fileName = "ChrpSong", menuName = "Custom/Chrp Song")]
public class Song : ScriptableObject
{
    /// <summary>
    /// The title of the song.
    /// </summary>
    public string Title;

    /// <summary>
    /// The artist who wrote the song.
    /// </summary>
    public string Artist;

    /// <summary>
    /// Beats per minute.
    /// </summary>
    public int BPM;

    /// <summary>
    /// Beats per bar.
    /// </summary>
    public int BPB;

    /// <summary>
    /// The main audio file for this song. 
    /// Should generally exclude the sound made by any [member instruments], as they have their own audio 
    /// files.
    /// </summary>
    public AudioClip Audio;

    /// <summary>
    /// The instruments used in this song.
    /// </summary>
    public List<Instrument> Instruments = new();

    public override string ToString()
    {
        return $"Song(Title: {Title}, Artist: {Artist}, BPM: {BPM}, BPB: {BPB})";
    }
}
