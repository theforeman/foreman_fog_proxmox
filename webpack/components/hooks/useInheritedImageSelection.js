import { useEffect } from 'react';

const useInheritedImageSelection = ({
  fromProfile,
  inheritedImageId,
  newVm,
  provisionMethod,
  setSelectedImageId,
}) => {
  useEffect(() => {
    const imageSelect = document.querySelector('#image_selection select');
    if (fromProfile || !newVm || !inheritedImageId || !imageSelect) {
      return undefined;
    }

    const restoreImageSelection = () => {
      const imageExists = Array.from(imageSelect.options).some(
        option => option.value === inheritedImageId
      );
      if (!imageExists) return;

      imageSelect.value = inheritedImageId;
      if (provisionMethod === 'image') {
        setSelectedImageId(inheritedImageId);
      }
    };

    restoreImageSelection();
    const observer = new MutationObserver(restoreImageSelection);
    observer.observe(imageSelect, { childList: true });

    return () => observer.disconnect();
  }, [
    fromProfile,
    inheritedImageId,
    newVm,
    provisionMethod,
    setSelectedImageId,
  ]);
};

export default useInheritedImageSelection;
