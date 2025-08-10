using UnityEngine;

/// <summary>
/// Represents a musical note in the game.
/// </summary>
[System.Serializable]
public class Note
{
    /// <summary>
    /// The track ("lane") that this note belongs to. 
    /// </summary>
    /// <remarks>
    /// Count starts on 0.
    /// </remarks>
    public int Track;

    /// <summary>
    /// The beat that this note shows up in.
    /// </summary>
    /// <remarks>
    /// Count starts on 0.
    /// </remarks>
    public int Beat;

    /// <summary>
    /// The offset from the [member beat] that this note lands on.
    /// </summary>
    /// <example>
    /// For example, a subbeat of <c>0</c> means the note is "on" the beat, and subbeat of <c>0.5</c> is halfway between the beats.
    /// </example>
    public float Subbeat;

    /// <summary>
    /// For how long this note should be pressed. 
    /// If this is <c>0</c>, the note just has to be hit. If it is greater than <c>0</c>, it has to be sustained for this long.
    /// </summary>
    public float Duration;

    /// <summary>
    /// How important this note is considered for the melodic structure. 
    /// Lower importance notes are only shown to users on a higher difficulty.
    /// A note with priority <c>0</c> is considered of highest importance.
    /// </summary>
    public int Priority;

    public Note(int track, int beat, float subbeat, int priority)
    {
        Track = track;
        Beat = beat;
        Subbeat = subbeat;
        Priority = priority;
        Duration = 0.0f;
    }

    public override string ToString()
    {
        return $"Note(Track: {Track}, Beat: {Beat + Subbeat}, Duration: {Duration}, Priority: {Priority})";
    }
}