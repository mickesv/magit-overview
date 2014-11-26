;; The MIT License (MIT)
;;
;; Copyright (c) 2014 Mikael Svahnberg
;;
;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be included in all
;; copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.


;; Buffer generation
;; --------------------
(require 'magit)

(defconst magit-overview-display-status-width 6)
(defconst magit-overview-display-repository-width 40)
(defconst magit-overview-display-dir-width 30)
(defconst magit-overview-display-format (format "%%-%ds %%-%ds %%-%ds" magit-overview-display-status-width
						  magit-overview-display-repository-width
						  magit-overview-display-dir-width))

(defun magit-overview-summarise (repo)
  "Run (magit-git-executable) on one repository and assemble the results thereof."
  (let ((filters '("M" "A" "D" "R" "C" "U" "??"))
	(startdir default-directory)
	(status)
	(dirty (list))
	)
    (cd (cdr repo))
    (setq status (mapcar 'car (mapcar 'split-string (process-lines magit-git-executable "status" "--porcelain")))) ;;  "-uno"
    (cd startdir)
    (dolist (f filters)      
      (when (member f status)
	(setq dirty (add-to-list 'dirty (substring f 0 1)))
	))
    dirty))

(defun magit-overview-prettify-summarise (repo)
  "Format details about one repository and insert into buffer."
  (let* ((dirty (or (magit-overview-summarise repo) nil))
	(str (format magit-overview-display-format (mapconcat 'identity dirty "") (car repo) (cdr repo))))
    (when dirty
      (setq str (propertize str 'face 'magit-item-highlight)))
    (insert str "\n")
    dirty))

(defun magit-overview-redisplay ()
  "Clear and (re-)fill the buffer with the repositories and their status"
  (interactive)
  (read-only-mode -1)
  (erase-buffer)
  (insert (propertize (format magit-overview-display-format "Status" "Repository" "Dir") 'face 'magit-section-title) "\n")
    
  (mapc 'magit-overview-prettify-summarise (magit-list-repos magit-repo-dirs))
  (read-only-mode)
  (goto-char (point-min)) (forward-line 1)    
)

(defun magit-overview ()
  "Create an overview of all git repositories reachable by magit through magit-repo-dirs"
  (interactive)
  (let ((buffer (get-buffer-create "*Git Overview*")))
    (set-buffer buffer)
    (magit-overview-mode)
    (magit-overview-redisplay)
    ;;(display-buffer buffer)
    (switch-to-buffer-other-window buffer)
  nil))
 
;; Helper functions for the keypress-functions
;; --------------------
(defun magit-overview-find-dir-on-current-line ()
  "Search for ' /' to find start of dir, then copy to end-of-line"
  (save-excursion
    (save-restriction
      (save-match-data
	(widen)
	(let ((start-search-pos (+ (line-beginning-position)
				   magit-overview-display-status-width
				   magit-overview-display-repository-width)))
	  (goto-char start-search-pos)		       
	  (if (search-forward " /" (line-end-position) t)
	      (let* ((start-of-dir (- (point) 1))
		     (dir (buffer-substring-no-properties start-of-dir (line-end-position))))
	  	dir)
	    nil)
	)))))


(defun magit-overview-find-dirty (direction)
  "search for a line with a dirty repository.
If direction is positive or t, search forward, else search backwards"
  (let ((step (cond ((numberp direction) (if (> direction 0) 1 -1))
		    ((t) 1)))
	)
    (forward-line step)
    (while (and (char-equal (char-after) ?\s)
		(not (eobp))
		(> (line-number-at-pos) 2))
      (forward-line step))))
			 
(defun magit-overview-mark-as-touched ()
  "Mark current line as touched by changing the face"
  (read-only-mode -1)
  (put-text-property (line-beginning-position)
		     (line-end-position)
		     'face 'magit-item-mark)
  (read-only-mode))
		     

;; Keypress interactions
;; --------------------		    
(defun magit-overview-open-magit ()
  "Open repo on this line with magit"
  (interactive)
  (if (> (line-number-at-pos) 1)
      (progn
	(magit-overview-mark-as-touched)
	(magit-status (or (magit-overview-find-dir-on-current-line) default-directory)))))

(defun magit-overview-open-dired ()
  "Open repo on this line with dired"
  (interactive)
  (if (> (line-number-at-pos) 1)
      (progn
	(magit-overview-mark-as-touched)
	(dired (magit-overview-find-dir-on-current-line)))))

(defun magit-overview-find-next-dirty ()
  "Go to next line with a dirty repository"
  (interactive)
  (magit-overview-find-dirty 1))

(defun magit-overview-find-prev-dirty ()
  "Go to next line with a dirty repository"
  (interactive)
  (magit-overview-find-dirty -1))

(defun magit-overview-quit-window (&optional kill-buffer)
  "Bury the buffer and delete its window.
With a prefix argument, kill the buffer instead."
  (interactive "P")
  (quit-window kill-buffer (selected-window)))

;; A tiny major mode
;; --------------------
(defvar magit-overview-mode-hook nil)
(defvar magit-overview-mode-map nil)

(if magit-overview-mode-map nil
  (setq magit-overview-mode-map (make-sparse-keymap))
  (define-key magit-overview-mode-map (kbd "<return>") 'magit-overview-open-magit)
  (define-key magit-overview-mode-map (kbd "d") 'magit-overview-open-dired)
  (define-key magit-overview-mode-map (kbd "n") 'magit-overview-find-next-dirty)
  (define-key magit-overview-mode-map (kbd "p") 'magit-overview-find-prev-dirty)
  (define-key magit-overview-mode-map (kbd "g") 'magit-overview-redisplay)
  (define-key magit-overview-mode-map (kbd "q") 'magit-overview-quit-window))


(defun magit-overview-mode ()
  "Major mode for magit-overview-mode.
Special commands:
\\{magit-overview-mode-map}"
  (interactive)
  (kill-all-local-variables)
  (setq major-mode 'magit-overview-mode)
  (setq mode-name "magit-overview")
  (use-local-map magit-overview-mode-map)
  (run-hooks magit-overview-mode-hook))


(provide 'magit-overview)
