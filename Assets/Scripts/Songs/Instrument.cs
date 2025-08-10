using System;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// Represents a musical instrument in the game.
/// </summary>
[Serializable]
public class Instrument
{
    /// <summary>
    /// The name of the instrument.
    /// </summary>
    public string Name;

    /// <summary>
    /// The unique audio for this instrument.
    /// </summary>
    public AudioClip Audio;

    /// <summary>
    /// The notes played by this instrument.
    /// </summary>
    public List<Note> Notes;

    public Instrument(string name)
    {
        Name = name;
        Notes = new List<Note>();
    }

    /// <summary>
    /// Gets all notes played by this instrument in a specific <paramref name="beat"/>.
    /// </summary>
    /// <param name="beat">The beat to check.</param>
    /// <returns>An array of notes played in the specified beat.</returns>
    public List<Note> NotesInBeat(int beat)
    {
        return Notes.FindAll(note => note.Beat == beat);
    }

    public override string ToString()
    {
        return $"Instrument(Name: {Name}, Notes Count: {Notes.Count})";
    }
}