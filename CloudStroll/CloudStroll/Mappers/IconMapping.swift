//
//  IconMapping.swift
//  CloudStroll
//
//  Created by Amey Sunu on 04/08/2025.
//

import Foundation


let iconMappings: [(keywords: [String], symbol: String)] = [
        // Food & Drink
        (["eat","dinner","lunch","meal"],       "fork.knife"),
        (["coffee","café","latte"],             "cup.and.saucer"),
        (["wine","drinks"],                     "wineglass.fill"),

        // Travel & Transport
        (["plane","flight","airport"],          "airplane"),
        (["train","metro","tram"],              "tram.fill"),
        (["drive","roadtrip"],                  "car.fill"),
        (["bike","cycling"],                    "bicycle"),

        // Outdoors & Nature
        (["hike","trail","mountain"],           "mountain.2.fill"),
        (["beach","ocean","sunny"],             "sun.max.fill"),
        (["forest","park","trees"],             "leaf.fill"),
        (["camp","tent","camping"],             "tent.fill"),

        // Culture & Entertainment
        (["museum","art","gallery"],            "paintpalette"),
        (["concert","music","band"],            "music.note.list"),
        (["movie","film","cinema"],             "film.fill"),

        // Urban & Lifestyle
        (["city","downtown"],                   "building.2.fill"),
        (["shopping","mall","store"],           "bag.fill"),
        (["cafe","coffee shop"],                "mug.fill"),

        // Weather & Time
        (["rain","storm"],                      "cloud.rain.fill"),
        (["snow","ski"],                        "snow"),
        (["sunset","sunrise"],                  "sunset.fill"),

        // Miscellaneous
        (["photo","camera","picture"],          "camera.fill"),
        (["reading","book","library"],          "book.fill")
    ]
