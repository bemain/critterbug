using UnityEngine;

public class Singleton : MonoBehaviour
{
    public static Singleton Instance { get; private set; }

    private void Awake()
    {
        // If there is an instance, and it's not me, delete myself.
        if (Instance != null && Instance != this)
        {
            Destroy(this);
        }
        else
        {
            Instance = this;
        }
    }

    void Start()
    {
        Song song = Resources.Load<Song>("Songs/JazzSwing/JazzSwing");
        Debug.Log($"Successfully loaded song: {song.Title} by {song.Artist}");
    }

    public Song[] Songs { get; private set; }
}