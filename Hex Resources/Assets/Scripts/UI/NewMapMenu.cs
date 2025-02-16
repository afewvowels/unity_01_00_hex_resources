﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class NewMapMenu : MonoBehaviour
{
    public HexGrid hexGrid;

    public HexMapGenerator mapGenerator;

    private bool generateMaps = true;

    private bool wrapping = true;

    public void Open()
    {
        HexMapCamera.Locked = true;
        gameObject.SetActive(true);
    }

    public void Close()
    {
        HexMapCamera.Locked = false;
        HexGameUI.menuOpen = false;
        gameObject.SetActive(false);
    }

    private void CreateMap(int x, int z)
    {
        if (generateMaps)
        {
            mapGenerator.GenerateMap(x, z, wrapping);
        }
        else
        {
            hexGrid.CreateMap(x, z, wrapping);
        }
        //HexMapCamera.ValidatePosition();
        Close();
    }

    public void CreateSmallMap()
    {
        CreateMap(20, 15);
    }

    public void CreateMediumMap()
    {
        CreateMap(40, 30);
    }

    public void CreateLargeMap()
    {
        CreateMap(80, 60);
    }

    public void ToggleMapGeneration(bool toggle)
    {
        generateMaps = toggle;
    }

    public void ToggleWrapping(bool toggle)
    {
        wrapping = toggle;
    }
}
