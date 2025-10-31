pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

/**
 * Fuzzy Matcher Service
 * Provides fuzzy matching and scoring algorithms for text search
 */
QtObject {
    id: root

    /**
     * Calculate a relevance score for a pattern matching against text
     * Higher scores indicate better matches
     * Returns 0 if pattern doesn't match
     */
    function score(pattern, text) {
        if (!pattern || !text)
            return 0;

        pattern = pattern.toLowerCase();
        text = text.toLowerCase();
        
        // Helper function to check if a position is at word boundary
        function isWordBoundary(text, index) {
            if (index === 0) return true;
            const prevChar = text[index - 1];
            return prevChar === ' ' || prevChar === '-' || prevChar === '_' || prevChar === ':';
        }
        
        // If exact substring match, return very high score
        const exactIndex = text.indexOf(pattern);
        if (exactIndex !== -1) {
            let score = 10000;
            // Huge bonus for matching at the start of the text
            if (exactIndex === 0) {
                score += 5000;
            }
            // Bonus for word boundary matches
            if (isWordBoundary(text, exactIndex)) {
                score += 3000;
            }
            return score;
        }
        
        // Fuzzy matching with scoring
        let patternIndex = 0;
        let textIndex = 0;
        let score = 0;
        let consecutiveMatches = 0;
        let maxConsecutive = 0;
        let wordStartMatches = 0;
        let firstMatchIndex = -1;
        let lastMatchIndex = -1;
        
        while (patternIndex < pattern.length && textIndex < text.length) {
            const patternChar = pattern[patternIndex];
            const textChar = text[textIndex];
            
            if (patternChar === textChar) {
                // Track first match position
                if (firstMatchIndex === -1) {
                    firstMatchIndex = textIndex;
                }
                
                // Check if this is at the start of a word
                if (isWordBoundary(text, textIndex)) {
                    wordStartMatches++;
                    score += 200; // Big bonus for word start
                }
                
                // Check if this is consecutive (immediately after last match)
                if (lastMatchIndex !== -1 && textIndex === lastMatchIndex + 1) {
                    consecutiveMatches++;
                } else {
                    consecutiveMatches = 1; // Start new consecutive sequence
                }
                
                if (consecutiveMatches > maxConsecutive) {
                    maxConsecutive = consecutiveMatches;
                }
                
                // Bonus for consecutive matches (exponential)
                score += consecutiveMatches * consecutiveMatches * 10;
                
                // Base score for matching
                score += 1;
                
                lastMatchIndex = textIndex;
                patternIndex++;
            }
            
            textIndex++;
        }
        
        // Must match all pattern characters
        if (patternIndex !== pattern.length) {
            return 0;
        }
        
        // Bonus for matches near the start of the text
        if (firstMatchIndex < 3) {
            score += 1000;
        } else if (firstMatchIndex < 10) {
            score += 300;
        }
        
        // Bonus for many consecutive matches
        score += maxConsecutive * 100;
        
        // Bonus for word start matches
        score += wordStartMatches * 150;
        
        // Penalty for longer text (prefer shorter, more relevant matches)
        const lengthDiff = text.length - pattern.length;
        score -= lengthDiff * 1;
        
        return score;
    }

    /**
     * Filter and sort an array of items by fuzzy matching score
     * @param items Array of items to filter
     * @param pattern Search pattern
     * @param textExtractor Function to extract text from each item (default: item => item.name)
     * @returns Array of items sorted by relevance score (highest first)
     */
    function filterAndSort(items, pattern, textExtractor) {
        if (!pattern || !pattern.trim()) {
            return items;
        }

        const searchText = pattern.toLowerCase().trim();
        const extractText = textExtractor || function(item) { return item.name || ""; };
        
        const scoredItems = [];
        for (let i = 0; i < items.length; i++) {
            const item = items[i];
            const text = extractText(item);
            const itemScore = score(searchText, text);
            if (itemScore > 0) {
                scoredItems.push({
                    item: item,
                    score: itemScore
                });
            }
        }
        
        // Sort by score (highest first)
        scoredItems.sort((a, b) => b.score - a.score);
        
        // Return just the items
        return scoredItems.map(scored => scored.item);
    }
}

